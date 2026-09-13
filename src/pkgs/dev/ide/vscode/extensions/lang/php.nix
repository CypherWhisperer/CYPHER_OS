# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/php.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.php.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
        # ────────────────────────────────────────────────────────────────
        # PHP — Core language intelligence
        # ────────────────────────────────────────────────────────────────
        # PHP Intelephense — primary language server
        # ────────────────────────────────────────────────────────────────
        # The backbone of PHP development in VSCode. Provides:
        #
        #   • Intelligent completion (functions, classes, methods,
        #     variables)
        #
        #   • Go-to-definition and find-all-references across the full
        #     project
        #
        #   • Real-time diagnostics (type errors, undefined symbols)
        #
        #   • Hover documentation, signature help
        #   • Code folding, document symbols, workspace indexing
        #
        # ────────────────────────────────────────────────────────────────
        # §INTELEPHENSE-VS-PHPTOOLS
        # ────────────────────────────────────────────────────────────────
        # This module installs Intelephense as the sole PHP language
        # server. DEVSense phptools-vscode (DEVSENSE.phptools-vscode) is
        # an alternative that offers deeper IntelliSense for large
        # Symfony/Laravel enterprise codebases and some additional
        # Blade-aware features. It was evaluated and intentionally
        # excluded because:
        #
        #   1. It competes directly with Intelephense — running both
        #      causes duplicate diagnostics, conflicting completions, and
        #      save-time lag.
        #
        #   2. Its full feature set requires a paid license; the free tier
        #      offers marginal gains over Intelephense for projects at
        #      CypherOS scale.
        #
        #   3. Intelephense's free tier covers 100% of DevLog's and most
        #      Laravel/Symfony projects' daily development needs.
        #
        # If Intelephense is outgrown on a very large enterprise codebase:
        #
        #   1. Remove bmewburn.vscode-intelephense-client from this list.
        #   2. Uncomment DEVSENSE.phptools-vscode.
        #   3. Remove the intelephense.* settings from userSettings.
        #
        #   4. Update "[php]".editor.defaultFormatter to
        #     "DEVSENSE.phptools-vscode".
        #
        # DEVSENSE alternative (commented out — see rationale above):
        # vscMkt."DEVSENSE".phptools-vscode
        vscMkt.bmewburn.vscode-intelephense-client

        # ────────────────────────────────────────────────────────────────
        # PHP Debug — Xdebug DAP client
        # ────────────────────────────────────────────────────────────────
        # Bridges Xdebug (installed via php.nix buildEnv) to VSCode's
        # native debugger UI. Enables:
        #   • Breakpoints (click left gutter or F9)
        #   • Step over / step into / step out
        #   • Variable inspection and watch expressions
        #   • Call stack navigation
        #   • Conditional breakpoints and logpoints
        #
        # Requires a launch.json in the project. VSCode will offer to
        # generate one when the Run & Debug panel (Ctrl+Shift+D) is opened
        # on a PHP project. The generated "Listen for Xdebug"
        # configuration works out of the box with the Xdebug settings in
        # php.nix (port 9003, idekey VSCODE).
        # ────────────────────────────────────────────────────────────────
        vscMkt.xdebug.php-debug

        # ────────────────────────────────────────────────────────────────
        # PHP — Static analysis & code style
        # ────────────────────────────────────────────────────────────────

        # ────────────────────────────────────────────────────────────────
        # PHPStan — inline static analysis diagnostics
        # ────────────────────────────────────────────────────────────────
        # Surfaces PHPStan findings (type errors, undefined methods, dead
        # code) as inline squiggles and Problems panel entries as you type
        #
        # Reads phpstan.neon from the project root for level and
        # configuration.
        #
        # NOTE: Verify the publisher ID at update time. The "swordev"
        # publisher is current as of mid-2026, but PHPStan-related
        # extensions have changed publisher accounts before. Run
        # `nix flake update`
        # on nix-vscode-extensions input and grep the result for "phpstan"
        # to confirm.
        # ────────────────────────────────────────────────────────────────
        vscMkt.swordev.phpstan

        # ────────────────────────────────────────────────────────────────
        # PHP CS Fixer — format on save
        # ────────────────────────────────────────────────────────────────
        # Calls the php-cs-fixer binary (installed via php.nix) on save.
        # Configured to use @PSR12 ruleset by default.
        # For Laravel projects, swap formatter to
        # open-southeners.laravel-pint.
        # ────────────────────────────────────────────────────────────────
        vscMkt.junstyle.php-cs-fixer

        # ────────────────────────────────────────────────────────────────
        # PHPDoc Blocker — documentation generation
        # ────────────────────────────────────────────────────────────────
        # Type `/**` above a function/class/property and press Enter to
        # generate a fully populated PHPDoc block with @param, @return,
        # and @throws tags. Saves repetitive boilerplate when documenting
        # PHP and framework code.
        # ────────────────────────────────────────────────────────────────
        vscMkt.neilbrayfield.php-docblocker

        # ────────────────────────────────────────────────────────────────
        # PHP — Testing
        # ────────────────────────────────────────────────────────────────

        # ────────────────────────────────────────────────────────────────
        # PHPUnit Test Explorer (recca0120)
        # ────────────────────────────────────────────────────────────────
        # Integrates PHPUnit and Pest with VSCode's native
        # Test Explorer UI:
        #   • Auto-discovers tests from phpunit.xml / phpunit.xml.dist
        #   • Run individual tests, files, or full suite from the sidebar
        #   • CodeLens indicators above each test method
        #   • Supports PHPUnit 7–12 and Pest
        #   • Reloads tests dynamically on composer.lock changes
        #   • Parallel test execution via ParaTest (if installed)
        #
        # ────────────────────────────────────────────────────────────────
        # NOTE: verify publisher is `recca0120` at install time —
        # the Test Explorer space has seen republishing under different
        # accounts.
        # ────────────────────────────────────────────────────────────────
        vscMkt.recca0120.vscode-phpunit

        # ────────────────────────────────────────────────────────────────
        # Pest Snippets (dansysanalyst)
        # ────────────────────────────────────────────────────────────────
        # Snippet set for Pest's DSL (it(), test(), expect(),
        # beforeEach(), etc.).
        #
        # Pest is now the Laravel-ecosystem default and works in vanilla
        # PHP too. Zero config required — snippets are available
        # immediately for .php files.
        # ────────────────────────────────────────────────────────────────
        vscMkt.dansysanalyst.pest-snippets

        # ────────────────────────────────────────────────────────────────
        # PHP — Framework-specific (future-proof)
        # ────────────────────────────────────────────────────────────────

        # ────────────────────────────────────────────────────────────────
        # Official Laravel extension (Laravel team)
        # ────────────────────────────────────────────────────────────────
        # As of 2026 this is the consolidated, official Laravel extension
        # — it replaced the fragmented community extensions
        # (Laravel Extra Intellisense, Laravel Goto View, Laravel Artisan,
        # etc.) that previously required installing separately. Provides:
        #   • Model, config, route, and view auto-completion
        #   • Click-to-definition for route names, view paths, config keys
        #   • Artisan command runner from the command palette
        #   • Blade directive IntelliSense (complements Blade extension)
        #
        # Activate when you start a Laravel project. No harm in having it
        # installed in the meantime; it only activates on Laravel project
        # detection.
        # ────────────────────────────────────────────────────────────────
        vscMkt.laravel.vscode-laravel

        # ────────────────────────────────────────────────────────────────
        # Blade syntax and snippets (onecentlin)
        # ────────────────────────────────────────────────────────────────
        # Blade template syntax highlighting, code folding, and common
        # directive snippets (@foreach, @if, @extends, @section,
        # @component, etc.). Pairs with the official Laravel extension.
        # ────────────────────────────────────────────────────────────────
        vscMkt.onecentlin.laravel-blade

        # ────────────────────────────────────────────────────────────────
        # Blade Formatter (shufo)
        # ────────────────────────────────────────────────────────────────
        # Auto-formats Blade templates with configurable indent and style
        # rules. Activate format-on-save for .blade.php files when using
        # Laravel. Config: .bladeformatter.json in project root.
        # ────────────────────────────────────────────────────────────────
        vscMkt.shufo.vscode-blade-formatter

        # ────────────────────────────────────────────────────────────────
        # Laravel Pint (open-southeners)
        # ────────────────────────────────────────────────────────────────
        # Pint is PHP-CS-Fixer with Laravel's opinionated house ruleset —
        # it ships pre-configured in new Laravel projects
        # (laravel/pint in composer.json).
        #
        # This extension calls the project-local `vendor/bin/pint` binary.
        #
        # WHEN WORKING IN LARAVEL: set "[php]".editor.defaultFormatter to
        # "open-southeners.laravel-pint" instead of "junstyle.php-cs-fixer".
        # Both are installed; the formatter switch is per-project
        # (workspace settings).
        # ────────────────────────────────────────────────────────────────
        vscMkt.open-southeners.laravel-pint

        # ────────────────────────────────────────────────────────────────
        # Symfony snippets
        # ────────────────────────────────────────────────────────────────
        # Common Symfony boilerplate: service definitions, controller
        # scaffolding, console command stubs, Twig directives, etc.
        #
        # NOTE: Symfony VSCode tooling has a smaller publisher pool than
        # Laravel's — verify the publisher ID (julien-deramond is current
        # as of mid-2026) with `nix flake update` before committing this
        # line.
        # uncomment when doing Symfony work
        # vscMkt.julien-deramond.symfony-snippets
        # ────────────────────────────────────────────────────────────────
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # PHP — Intelephense
      # ────────────────────────────────────────────────────────────────────────

      # Maximum file size Intelephense will index (bytes).
      # Raise if vendor libraries contain large generated files that get skipped.
      "intelephense.files.maxSize" = 5000000;

      # Paths Intelephense adds to the index (useful for framework stubs).
      # Normally auto-resolved from composer.json vendor paths — leave empty
      # unless you have source outside the project root.
      "intelephense.environment.includePaths" = [ ];

      # PHP version hint — helps Intelephense choose the right signatures.
      # Match this to pkgs.php version in php.nix.
      "intelephense.environment.phpVersion" = "8.3";

      # Point Intelephense at the Nix-managed PHP binary.
      # Use the path of your phpEnv's php binary. The @default@ marker
      # tells Intelephense to resolve from PATH (which includes your Nix PHP).
      # If resolution fails, set this to the full Nix store path of cfg.package.
      "intelephense.executablePath" = "php";

      # Report undefined types, methods, properties, and functions as diagnostics.
      "intelephense.diagnostics.undefinedTypes" = true;
      "intelephense.diagnostics.undefinedFunctions" = true;
      "intelephense.diagnostics.undefinedConstants" = true;
      "intelephense.diagnostics.undefinedClassConstants" = true;
      "intelephense.diagnostics.undefinedMethods" = true;
      "intelephense.diagnostics.undefinedProperties" = true;

      # §INTELEPHENSE-FORMAT-DISABLED
      # Intelephense's built-in formatter is explicitly DISABLED here.
      # Reason: running Intelephense formatting AND PHP-CS-Fixer simultaneously
      # causes save-time fights — one extension reformats what the other just
      # wrote, resulting in flickering and non-idempotent saves.
      # PHP-CS-Fixer (configured below) is the sole formatting authority.
      # If you ever switch to DEVSense phptools-vscode as the language server,
      # revisit this: DEVSense has its own format authority and PHP-CS-Fixer
      # integration is handled differently.
      "intelephense.format.enable" = false;

      # ────────────────────────────────────────────────────────────────────────
      # PHP — Formatting (PHP-CS-Fixer as sole authority)
      # ────────────────────────────────────────────────────────────────────────

      # Per-language editor overrides. The "[php]" key scopes settings to PHP
      # files only, leaving your JS/TS/JSON formatter preferences untouched.
      # PSR-12 convention uses 4-space indentation — distinct from the 2-space
      # style common in JS/TS projects.
      "[php]" = {
        "editor.defaultFormatter" = "junstyle.php-cs-fixer";
        "editor.formatOnSave" = true;
        "editor.tabSize" = 4;
        "editor.insertSpaces" = true;
      };

      # PHP-CS-Fixer binary path.
      # Tries the project-local vendor binary first (preferred — keeps projects
      # using their own pinned php-cs-fixer version). Falls back to the system
      # binary (installed via php.nix) if vendor/bin is absent.
      "php-cs-fixer.executablePath" = "\${workspaceFolder}/vendor/bin/php-cs-fixer";
      "php-cs-fixer.executablePathOnSave" = true;
      "php-cs-fixer.onsave" = true;
      "php-cs-fixer.lastDownload" = null;

      # Ruleset. @PSR12 is the standard for vanilla PHP and most frameworks.
      # Laravel projects use pint.json instead — in that case switch formatter
      # to "open-southeners.laravel-pint" in workspace settings (not here).
      "php-cs-fixer.rules" = "@PSR12";
      "php-cs-fixer.config" = ".php-cs-fixer.dist.php"; # project-level config file if present

      # ────────────────────────────────────────────────────────────────────────
      # PHP — PHPStan (inline static analysis)
      # ────────────────────────────────────────────────────────────────────────
      "phpstan.enabled" = true;

      # PHPStan binary path — project-local vendor binary preferred, as above.
      "phpstan.path" = "\${workspaceFolder}/vendor/bin/phpstan";

      # §PHPSTAN-LEVEL — default 5; see comment in php.nix for the full level guide.
      # Level 5 gives substantial type-safety coverage without overwhelming
      # noise on actively-developed projects. Ratchet up gradually:
      #   • Once DevLog's architecture has settled → level 6 or 7
      #   • On a new greenfield project from day 1 → start at max
      # Override per project in phpstan.neon:
      #   parameters:
      #     level: 7
      "phpstan.level" = "5";

      # Path to phpstan.neon configuration file (relative to project root).
      "phpstan.configFile" = "phpstan.neon";

      # ────────────────────────────────────────────────────────────────────────
      # PHP — Debugging (Xdebug via PHP Debug extension)
      # ────────────────────────────────────────────────────────────────────────

      # Validate PHP path: if VSCode's built-in PHP validator complains about
      # not finding PHP, this setting points it at the right binary.
      # The "php" bare command resolves through PATH to the Nix phpEnv binary.
      "php.validate.executablePath" = "php";
      "php.validate.enable" = true;

      # Debug extension: port must match xdebug.client_port in php.nix (9003).
      # The launch.json generated by "Listen for Xdebug" uses this as default.
      # Documented here for cross-reference — the extension reads it from
      # launch.json, not from settings.json directly.
      # "php.debug.port" = 9003;  # handled in launch.json per project

      # ────────────────────────────────────────────────────────────────────────
      # PHP — Test explorer
      # ────────────────────────────────────────────────────────────────────────

      # PHP binary for the test runner (used by recca0120.vscode-phpunit).
      "phpunit.php" = "php";

      # Preferred test runner binary resolution order:
      # 1. ${workspaceFolder}/vendor/bin/phpunit  (Composer per-project install)
      # 2. phpunit on system PATH (system-wide fallback from php.nix)
      "phpunit.phpunit" = "\${workspaceFolder}/vendor/bin/phpunit";

      # ────────────────────────────────────────────────────────────────────────
      # Blade (Laravel) — only relevant once you start a Laravel project
      # ────────────────────────────────────────────────────────────────────────
      "[blade]" = {
        "editor.defaultFormatter" = "shufo.vscode-blade-formatter";
        "editor.formatOnSave" = true;
        "editor.tabSize" = 4;
      };
    };
  };
}
