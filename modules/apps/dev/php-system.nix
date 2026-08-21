# ──────────────────────────────────────────────────────────────────────────────
# modules/apps/dev/php-system.nix
#
# CyherOS PHP Development Environment.
# ──────────────────────────────────────────────────────────────────────────────
#
# WHAT THIS MODULE PROVIDES
# ──────────────────────────────────────────────────────────────────────────────
#  • PHP runtime via pkgs.php.buildEnv (idiomatic Nix, reproducible)
#  • Xdebug (step debugging, DAP for both VSCode and CypherIDE)
#  • Composer (built against the same PHP binary — critical, see §COMPOSER)
#  • PHPStan   — primary static analysis, editor-integrated
#  • Psalm     — secondary static analysis, security/taint focus (see §PSALM)
#  • PHP-CS-Fixer — code style enforcement (PSR-12 / Laravel Pint base)
#  • Phpactor  — PHP Language Server for Neovim (CypherIDE session)
#  • PsySH     — interactive PHP REPL
#  • Symfony CLI — framework tooling (Laravel installer via Composer global)
#  • COMPOSER_HOME + PATH wired for global Composer binaries
#
# STATIC ANALYSIS STRATEGY
# ──────────────────────────────────────────────────────────────────────────────
#  PHPStan is the day-to-day, editor-integrated analyser (level 5 by default,
#  see §PHPSTAN-LEVEL). Psalm is installed alongside it — not to run
#  simultaneously in editors, but as a dedicated security audit tool:
#
#    $ psalm --taint-analysis
#
#  Psalm's taint analysis traces user input (HTTP params, cookies) to dangerous
#  sinks (SQL, HTML output, shell_exec) — catching injection vectors that
#  PHPStan's type system doesn't model. Both tools install cleanly without
#  conflict; only PHPStan is wired into editor LSP chains.
#
# NOTE: RELATED SESSIONS / FUTURE WORK
# ──────────────────────────────────────────────────────────────────────────────
#  CypherIDE (Neovim): a dedicated session will wire Phpactor (installed here
#  system-wide), nvim-dap-php, conform.nvim → php-cs-fixer, and nvim-lint →
#  PHPStan into the Neovim configuration. Decisions and constraints that affect
#  that session are documented inline below with the §NEOVIM-* tags.
#
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cypher-os.apps.dev.languages.php;
in

{
  imports = [ ./options.nix ];
  config =
    lib.mkIf
      (
        config.cypher-os.apps.enable
        && config.cypher-os.apps.dev.enable
        && config.cypher-os.apps.dev.languages.enable
        && cfg.enable
      )
      {

        environment.systemPackages = [

          # ──────────────────────────────────────────────────────────────────────────────
          # PHP Runtime
          # ──────────────────────────────────────────────────────────────────────────────
          # cfg.package resolves to the phpEnv buildEnv defined in the let block
          # in options.nix (PHP 8.3 + Xdebug + common extensions). It is exposed as an
          # option so it can be overridden per-host without editing this file.
          cfg.package

          # ──────────────────────────────────────────────────────────────────────────────
          # Composer
          # ──────────────────────────────────────────────────────────────────────────────
          # §COMPOSER — Must be built against the SAME PHP binary as cfg.package.
          # This is why we derive Composer from cfg.package.packages.composer
          # rather than pkgs.php83Packages.composer or a standalone derivation.
          #
          # The .packages attribute on a PHP buildEnv exposes all tools from the
          # php-packages scope, scoped to that specific PHP version and build.
          # This ensures: runtime PHP version == Composer's PHP version ==
          # extension set used by tools.
          #
          # If you override cfg.package (option above), Composer updates
          # automatically to match — no manual coordination required.
          cfg.package.packages.composer

          # ──────────────────────────────────────────────────────────────────────────────
          # PHP-CS-Fixer — code style enforcement
          # ──────────────────────────────────────────────────────────────────────────────
          # Automatically rewrites PHP source to match a chosen style standard.
          # Default configuration: @PSR12 (see §VSCODE-SETTINGS and the CypherIDE
          # PHP session for editor-side wiring).
          #
          # PINT NOTE (Laravel):
          # Laravel Pint is PHP-CS-Fixer with Laravel's house ruleset. Inside a
          # Laravel project you will use Pint (via `composer require laravel/pint
          # --dev`) rather than calling this binary directly. The skill and mental
          # model transfer 1:1 — Pint is not a new paradigm.
          # Config files: .php-cs-fixer.dist.php (vanilla) | pint.json (Laravel)
          cfg.package.packages.php-cs-fixer

          # ──────────────────────────────────────────────────────────────────────────────
          # PHPStan — primary static analysis
          # ──────────────────────────────────────────────────────────────────────────────
          # nixpkgs exposes phpstan at the top level (pkgs.phpstan). The old path
          # php83Packages.phpstan now throws — this is intentional by nixpkgs.
          #
          # §PHPSTAN-LEVEL
          # Level 0 = lax (only obvious errors). Level max = strictest.
          # CypherOS default: level 5 (substantial coverage without overwhelming
          # noise on actively-developed projects).
          #
          # Levels at a glance:
          #   0  — basic type checks, undefined variables
          #   1  — possibly undefined variables, unknown magic methods
          #   2  — unknown methods on mixed types
          #   3  — return type checks
          #   4  — dead code detection, always-true conditions
          #   5  — type check on method calls, checking passed arguments ← default
          #   6  — checks missing typehints
          #   7  — reports partially wrong union types
          #   8  — reports nullable type mismatches
          #   9  — requires explicit types on all properties
          #   max — above, plus additional strictness; start here for greenfield
          #
          # Level is set in phpstan.neon at the project root, NOT globally.
          # The system-wide binary is just the runner; rules come from per-project
          # phpstan.neon. See: https://phpstan.org/config-reference
          pkgs.phpstan

          # ──────────────────────────────────────────────────────────────────────────────
          # Psalm — secondary static analysis (security / taint focus)
          # ──────────────────────────────────────────────────────────────────────────────
          # §PSALM — Usage pattern:
          #
          # PHPStan is the editor-integrated daily driver. Psalm runs as a
          # dedicated security audit tool, not continuously in the editor:
          #
          #   $ psalm --taint-analysis
          #
          # Psalm's taint analysis traces user-supplied data (HTTP params, cookies,
          # headers, file uploads) through the codebase to dangerous sinks:
          # SQL queries, HTML output, shell_exec, file writes, etc. This catches
          # injection vulnerabilities (SQLi, XSS, path traversal) that PHPStan's
          # type system cannot model, since PHPStan reasons about types not data
          # provenance.
          #
          # Both tools coexist without conflict — they are independent CLI tools.
          # Only PHPStan is wired into editor LSP chains (VSCode + Neovim).
          # Psalm runs on-demand (locally or as a CI security gate).
          #
          # Configuration: psalm.xml at the project root.
          # See: https://psalm.dev/docs/running_psalm/configuration/
          #
          # DISABLE: if per-project `composer require --dev vimeo/psalm` covers
          # all your Psalm invocations and you never want the system-wide binary,
          # comment out this line. The security argument for keeping it system-wide:
          # you can run `psalm --taint-analysis` on projects that don't require it
          # in composer.json without any project-level setup.
          cfg.package.packages.psalm

          # ──────────────────────────────────────────────────────────────────────────────
          # PsySH — interactive PHP REPL
          # ──────────────────────────────────────────────────────────────────────────────
          # pkgs.psysh is exposed top-level in nixpkgs (old php83Packages.psysh throws).
          #
          # Useful for exploring MVC class behaviour interactively:
          #   $ psysh
          #   >>> require 'vendor/autoload.php';
          #   >>> $user = new App\Models\User();
          #   >>> $user->posts()->count();
          #
          # Laravel's `php artisan tinker` wraps PsySH under the hood. Having it
          # system-wide provides the same experience in vanilla PHP projects.
          pkgs.psysh

          # ──────────────────────────────────────────────────────────────────────────────
          # Phpactor — PHP Language Server for Neovim (CypherIDE)
          # ──────────────────────────────────────────────────────────────────────────────
          # §NEOVIM-PHPACTOR
          # Installed system-wide so CypherIDE can resolve `phpactor` on PATH
          # without relying on Mason, npm, or any imperative install mechanism.
          # This preserves the declarative/reproducible posture of CypherOS.
          #
          # Phpactor is the chosen LSP backend for Neovim over Intelephense because:
          #   1. Available in nixpkgs (no npm overlay needed)
          #   2. FOSS (MIT), actively maintained
          #   3. Ships built-in integrations for PHP-CS-Fixer and PHPStan:
          #        phpactor config:set language_server_php_cs_fixer.enabled true
          #        phpactor config:set language_server_phpstan.enabled true
          #   4. Reads composer.json/vendor autoload maps for cross-file navigation
          #
          # §NEOVIM-PHPACTOR-CONFIG
          # Phpactor's runtime config lives at ~/.config/phpactor/phpactor.json.
          # Consider managing it via home.file in HM for reproducibility:
          #   home.file.".config/phpactor/phpactor.json".text = builtins.toJSON { ... };
          # The CypherIDE PHP session will determine the final approach.
          pkgs.phpactor

          # ──────────────────────────────────────────────────────────────────────────────
          # Symfony CLI
          # ──────────────────────────────────────────────────────────────────────────────
          # `symfony new`, `symfony serve`, `symfony console`, `symfony check:security`
          #
          # §SYMFONY-CLI-PHP-RESOLUTION — Known nixpkgs issue:
          # symfony-cli may prefer a system PHP binary over the Nix-managed one if
          # there is a PATH ordering issue or a non-Nix PHP present. On CypherOS
          # (pure Nix, no system PHP package manager), this is a non-issue.
          # If it ever becomes a problem, the workaround is:
          #   pkgs.symfony-cli.overrideAttrs (old: {
          #     nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
          #     postInstall = "wrapProgram $out/bin/symfony --set PATH ${cfg.package}/bin";
          #   })
          pkgs.symfony-cli

          # ──────────────────────────────────────────────────────────────────────────────
          # PHP_CodeSniffer — phpcs + phpcbf (combined package)
          # ──────────────────────────────────────────────────────────────────────────────
          # Included for completeness: WordPress coding standards, legacy enterprise
          # codebases, and projects with PHPCS-based CI gates.
          #
          # NOTE: the old nixpkgs attributes phpcs and phpcbf now THROW. The
          # replacement is php-codesniffer which provides BOTH binaries:
          #   phpcs   — reports violations
          #   phpcbf  — fixes violations (Code Beautifier and Fixer)
          #
          # For vanilla PHP and Laravel work, PHP-CS-Fixer is the preferred tool.
          # php-codesniffer is here for compatibility with projects that mandate it.
          cfg.package.packages.php-codesniffer

          # ──────────────────────────────────────────────────────────────────────────────
          # PHPMD — PHP Mess Detector
          # ──────────────────────────────────────────────────────────────────────────────
          # Analyses for code complexity, duplication, overly long methods/classes,
          # dead code, and naming convention violations. Complements PHPStan (which
          # focuses on type correctness) with structural/quality signals.
          # Config: phpmd.xml or `--ruleset cleancode,codesize,naming,unusedcode`
          cfg.package.packages.phpmd

          # ──────────────────────────────────────────────────────────────────────────────
          # Commented-out tools — enable as projects require
          # ──────────────────────────────────────────────────────────────────────────────

          # PHPUnit (system-wide fallback)
          # Prefer vendor/bin/phpunit from per-project Composer install.
          # System-wide is a fallback for ad-hoc script testing outside a project.
          # cfg.package.packages.phpunit

          # Phan — deep static analysis using PHP's ast extension
          # More conservative than PHPStan; used in large legacy codebases.
          # cfg.package.packages.phan

          # GrumPHP — Git commit hook runner (runs PHPStan, PHPCS, tests on commit)
          # Useful in team environments to enforce quality gates pre-push.
          # cfg.package.packages.grumphp

          # PHP Parallel Lint — fast syntax-only check across all PHP files
          # Much faster than `php -l` on large codebases. Good CI pre-check.
          # cfg.package.packages.php-parallel-lint

          # Phive — PHAR installation manager (alternative to global Composer tools)
          # cfg.package.packages.phive

          # Deployer — PHP deployment tool
          # Note: deployer was removed from phpPackages and is now a top-level pkg.
          # pkgs.deployer

        ];

        # ──────────────────────────────────────────────────────────────────────────────
        # Environment: Composer global binary PATH
        # §COMPOSER-PATH-CONVENTION
        # ──────────────────────────────────────────────────────────────────────────────
        # Sets COMPOSER_HOME explicitly to the XDG-standard path and prepends
        # the global Composer bin directory to PATH.
        #
        # Without COMPOSER_HOME: Composer may default to ~/.composer (non-XDG),
        # causing a mismatch between where binaries are installed and what PATH
        # points to.
        #
        # Without PATH addition: globally-installed tools (laravel, pest, phpunit
        # installed via `composer global require`) are unreachable as bare commands.
        #
        # HOW THIS WORKS IN NIXOS:
        # environment.shellInit produces a shell snippet sourced by /etc/profile.d
        # for all interactive login shells (bash, zsh, fish). This means $HOME
        # expands correctly per-user at session start — making user-local paths
        # like ~/.config/composer/vendor/bin work without hardcoding a username.
        #
        # NOTE FOR NIXOS + HOME MANAGER SETUPS:
        # If you prefer to manage this exclusively at the Home Manager level
        # (e.g. to restrict it to a specific user), comment out environment.shellInit
        # below and add instead in your HM config:
        #
        #   home.sessionPath = [ "$HOME/.config/composer/vendor/bin" ];
        #   home.sessionVariables.COMPOSER_HOME = "$HOME/.config/composer";
        #
        # Both approaches achieve the same result; the NixOS-level approach here
        # applies to all users on the machine, which is appropriate for CypherOS's
        # single-user desktop profile.
        # ──────────────────────────────────────────────────────────────────────────────
        environment.shellInit = lib.mkIf cfg.withComposerGlobalPath ''
          # Composer global bin — added by modules/apps/dev/php-system.nix
          export COMPOSER_HOME="$HOME/.config/composer"
          export PATH="$HOME/.config/composer/vendor/bin:$PATH"
        '';

        # ──────────────────────────────────────────────────────────────────────────────
        # Notes affecting other modules / sessions
        # ──────────────────────────────────────────────────────────────────────────────
        #
        # §-NEOVIM-DECISIONS — for the CypherIDE PHP tooling session:
        #
        # 1. LSP:       Phpactor (installed above) via nvim-lspconfig 'phpactor' server.
        #               No Mason/npm required — phpactor is on system PATH.
        #
        # 2. Formatter: conform.nvim → php-cs-fixer binary (also on system PATH).
        #               Rule: @PSR12. Format-on-save = true.
        #               Mirror the VSCode formatter exactly for consistency.
        #
        # 3. Linting:   Phpactor's built-in PHPStan integration (preferred — no
        #               separate nvim-lint source needed):
        #                 phpactor config:set language_server_phpstan.enabled true
        #               Fallback: nvim-lint phpstan linter source.
        #
        # 4. Debugging: nvim-dap + nvim-dap-php.
        #               Adapter connects to Xdebug on port 9003.
        #               ⚠ xdebug.idekey in extraConfig above (currently "VSCODE")
        #               must match the idekey expected by nvim-dap-php, OR set
        #               nvim-dap-php to accept any idekey (idekey = "").
        #               Decide in the CypherIDE session and update extraConfig here.
        #
        # 5. Treesitter: add 'php' to nvim-treesitter parser list.
        #
        # 6. Snippets:  friendly-snippets (via LuaSnip) ships a PHP snippet set.
        #               Covers class boilerplate, PSR-4 namespaces, PHPDoc blocks.
        #
      };
}
