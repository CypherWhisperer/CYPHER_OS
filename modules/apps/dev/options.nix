{ lib, pkgs, ... }:

let
  # ──────────────────────────────────────────────────────────────────────────────
  # §-PHPENV — PHP Runtime Build
  # ──────────────────────────────────────────────────────────────────────────────
  # pkgs.php.buildEnv composes a PHP binary with exactly the extensions listed
  # below, injecting them into php.ini at derivation build time. This is the
  # idiomatic Nix approach — it avoids the "install PHP then hope extensions
  # resolve at runtime" antipattern and guarantees every extension is declared,
  # versioned, and reproducible across rebuilds.
  #
  # The `enabled` argument contains the extensions already compiled into the
  # base PHP binary (openssl, json, mbstring core subset, etc.). The pattern:
  #
  #   enabled ++ (with all; [ ... ])
  #
  # means: keep all defaults, then ADD the listed extras. To REMOVE a default
  # extension (rare, security hardening use-case):
  #
  #   (lib.filter (e: e.extensionName != "simplexml") enabled) ++ (with all; [ ... ])
  #
  # VERSION PINNING
  # ──────────────────────────────────────────────────────────────────────────────
  # pkgs.php → latest stable in nixpkgs (PHP 8.3 as of nixos-unstable mid-2026).
  # To pin a specific version, swap the base:
  #   pkgs.php82  → PHP 8.2 (active LTS)
  #   pkgs.php83  → PHP 8.3 (current stable)
  #
  # §-DEVSHELL-NOTE — PER-PROJECT VERSION PINNING
  # ──────────────────────────────────────────────────────────────────────────────
  # The system-wide PHP declared here is the baseline runtime that editors,
  # language servers, and tooling (Phpactor, PHPStan, PHP-CS-Fixer) resolve
  # against. It is intentionally version-agnostic at the system level.
  #
  # For per-project pinning, the proper Nix idiom is a per-project devShell
  #  (flake.nix  or devenv.nix) that declares its own phpEnv with the pinned
  # version. This keeps the system-wide installation clean while each project can
  # declare its own exact runtime contract.
  #
  # This system-wide PHP is the fallback for contexts outside per-project envs
  # (e.g, editors outside the devenv shell, global CLI tools,
  #  Phpactor LSP resolution, etc.).
  #
  # ──────────────────────────────────────────────────────────────────────────────
  phpEnv = pkgs.php.buildEnv {
    extensions = (
      { enabled, all }:
      enabled
      ++ (with all; [

        # ──────── Core: always needed for any non-trivial PHP project ───────────
        pdo # PDO base interface; required by pdo_mysql, pdo_sqlite, etc.
        pdo_mysql # MySQL/MariaDB via PDO.
        pdo_sqlite # SQLite via PDO — lightweight testing without a full DB server
        mbstring # Multibyte string functions; required by PSR libs and frameworks
        intl # Internationalization — required by Symfony and i18n-aware code
        zip # Composer needs this to extract packages
        opcache # Bytecode cache — mandatory in any non-trivial PHP project
        curl # HTTP client; Laravel/Symfony HTTP facades depend on it

        # ──────── Debugging ──────────────────────────────────────────────────────
        # §XDEBUG-NOTE: see extraConfig below for the full constraint documentation.
        xdebug

        # ──────── Data formats ───────────────────────────────────────────────────
        xml # XML parsing; required by some Composer packages and SOAP
        simplexml # Simplified XML; often pulled in by xml-heavy libraries
        dom # DOM manipulation; needed by PHPUnit HTML coverage output
        xmlreader # Streaming XML reader — large document processing
        xmlwriter # Streaming XML writer
        xsl # XSLT transformations

        # ──────── PostgreSQL (future: if a project uses Postgres instead of MySQL) ─
        pdo_pgsql # PostgreSQL via PDO
        pgsql # PostgreSQL native functions

        # ──────── Image processing ────────────────────────────────────────────────
        # gd            # GD library — basic image manipulation
        imagick # ImageMagick binding — more capable than GD

        # ──────── Math / crypto ─────────────────────────────────────────────────
        bcmath # Arbitrary-precision math; required by Laravel and payment SDKs
        sodium # libsodium crypto; Laravel uses this for encryption by default

        # ──────── Caching / message queues (future: Laravel cache, jobs, events) ─
        # redis         # Redis extension — needed when switching to Redis cache/queue
        # memcached     # Memcached alternative — prefer Redis for new projects

        # ──────── Other contrib extensions ──────────────────────────────────────
        mongodb # MongoDB driver — only if you use a Mongo-backed project
        yaml # YAML parsing — useful for Symfony config and test fixtures
        apcu # Shared memory cache — useful as a local session/cache backend

        # ──────── Code coverage (CI/CD use case) ─────────────────────────────────
        # pcov          # Fast code-coverage driver
        #               # ⚠ CONFLICT: xdebug and pcov cannot be loaded simultaneously.
        #               #   For CI coverage runs, build a separate phpEnv WITHOUT xdebug
        #               #   and WITH pcov. Example:
        #               #     pkgs.php.buildEnv {
        #               #       extensions = ({ enabled, all }:
        #               #         enabled ++ (with all; [ pdo pdo_mysql mbstring pcov ]));
        #               #     }
      ])
    );

    extraConfig = ''
      ; ──────────────────────────────────────────────────────────────────────────────
      ; CypherOS PHP runtime configuration — local development baseline
      ; ──────────────────────────────────────────────────────────────────────────────
      ; These settings are appropriate for local development only.
      ; Production services (php-fpm, Apache, nginx) should override via their
      ; own service-level php.ini or NixOS phpfpm.phpOptions, not here.
      ; ──────────────────────────────────────────────────────────────────────────────

      memory_limit            = 512M
      max_execution_time      = 60
      upload_max_filesize     = 64M
      post_max_size           = 64M

      display_errors          = on
      display_startup_errors  = true
      html_errors             = false   ; plain text is easier to read in terminal/logs
      error_reporting         = E_ALL

      ; log_errors            = on
      ; error_log             = /tmp/php_errors.log

      ; ──────────────────────────────────────────────────────────────────────────────
      ; §XDEBUG-NOTE — Critical cross-editor constraint
      ; ──────────────────────────────────────────────────────────────────────────────
      ; Xdebug connects to a DAP client (debugger) using idekey to select which
      ; listening client to target. Both VSCode (PHP Debug extension) and Neovim
      ; (nvim-dap-php) act as such clients.
      ;
      ; ⚠ MATCHING RULE: the xdebug.idekey value here MUST match what your editor
      ;   DAP client expects. Mismatches cause silent failures — Xdebug connects
      ;   to nothing and breakpoints never trigger.
      ;
      ;   VSCode:  In launch.json "Listen for Xdebug" → no idekey filter by default,
      ;            but the PHP Debug extension accepts any idekey. The VSCODE value
      ;            here is conventional and works out of the box.
      ;
      ;   Neovim:  In nvim-dap-php adapter config → set idekey to match this value,
      ;            OR leave the Neovim side as "" (accept any) for simplicity.
      ;            See the CypherIDE PHP tooling session for the exact Lua config.
      ;
      ; If you change xdebug.idekey: update BOTH editor configs simultaneously.
      ;
      ; PORT: Xdebug 3+ defaults to port 9003. If you still have legacy Xdebug 2
      ; config anywhere (older Docker images, remote servers), that used port 9000.
      ; Do not mix them — set client_port explicitly everywhere as done here.
      ;
      ; MODES:
      ;   debug    — step debugging  ← what you want locally
      ;   coverage — code coverage   ← set this in CI; ⚠ conflicts with pcov
      ;   profile  — Cachegrind output for profiling
      ;   trace    — function call trace to file
      ;   off      — disables Xdebug effect without unloading the extension
      ;   develop  — extended error display (DX quality-of-life in local dev)
      ;
      ; To enable multiple modes simultaneously:
      ;   xdebug.mode = debug,develop
      ; ──────────────────────────────────────────────────────────────────────────────
      xdebug.mode               = debug
      xdebug.start_with_request = yes
      xdebug.client_host        = 127.0.0.1
      xdebug.client_port        = 9003
      xdebug.discover_client_host = 1
      xdebug.idekey             = VSCODE

      ; xdebug.log            = /tmp/xdebug.log    ; uncomment to diagnose connection failures
      ; xdebug.log_level      = 7                  ; 0 = errors only, 7 = verbose, 10 = everything
      ; xdebug.max_nesting_level = 512             ; raise if you hit "Maximum function nesting level" in deep recursion
    '';
  };

in

{
  options.cypher-os.apps.dev = {
    enable = lib.mkEnableOption "CypherOS development environment";
    git.enable = lib.mkEnableOption "Git Version Control System";
    ssh.enable = lib.mkEnableOption "Enable SSH client configuration";
    devenv.enable = lib.mkEnableOption "Enable devenv + direnv project shell tooling";
    php = {
      enable = lib.mkEnableOption "PHP development environment (runtime, tooling, Composer PATH)";

      package = lib.mkOption {
        type = lib.types.package;
        default = phpEnv;
        description = ''
          The PHP runtime to install system-wide. Defaults to the buildEnv
          defined in this module (current stable + Xdebug + common extensions).

          Override to swap to a version-pinned or extension-customised build
          without editing this file:

            cypher-os.apps.dev.php.package = pkgs.php82.buildEnv {
              extensions = ({ enabled, all }: enabled ++ (with all; [ xdebug pdo_mysql ]));
              extraConfig = "memory_limit = 256M";
            };

          Note: if you override this, also update Phpactor's resolving PHP path
          so the language server stays in sync with the runtime you're using.
        '';
      };

      withComposerGlobalPath = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          §COMPOSER-PATH-CONVENTION
          ────────────────────────────────────────────────────────────────────────
          Whether to add the Composer global bin directory to PATH and set
          COMPOSER_HOME to the XDG-standard location.

          Composer installs globally required packages (laravel/installer,
          phpunit, psalm, etc.) under:

            $COMPOSER_HOME/vendor/bin
            → ~/.config/composer/vendor/bin  (with COMPOSER_HOME set below)

          Without this on PATH, globally-installed tools are unreachable
          without full path invocation. With it, `laravel new`, `phpunit`,
          `psalm`, etc. work as bare commands from any terminal.

          WHY COMPOSER_HOME IS SET EXPLICITLY:
          Without the env var, Composer may default to ~/.composer (non-XDG)
          on some systems. Setting it explicitly to ~/.config/composer keeps
          Composer's global state under the XDG_CONFIG_HOME tree alongside
          all other CypherOS user config.

          SET TO false FOR:
          • CI containers or build environments that import this module but
            should not inherit user PATH mutations.
          • Hermetic devShells where you want zero ambient global tools.
        '';
      };

      # ──────────────────────────────────────────────────────────────────────────────
      # Future option ideas (not yet implemented):
      # ──────────────────────────────────────────────────────────────────────────────
      # phpStanLevel = lib.mkOption { type = lib.types.int; default = 5; ... };
      # withSymfonyCli = lib.mkOption { type = lib.types.bool; default = true; ... };
      # withPsysh = lib.mkOption { type = lib.types.bool; default = true; ... };
      # ──────────────────────────────────────────────────────────────────────────────
    };
  };
}
