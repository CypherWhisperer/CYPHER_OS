# modules/apps/editor/vscode.nix
#
# Home Manager module for VSCode and its forks (Cursor, Antigravity).
#
# ARCHITECTURE:
#   VSCode forks share one settings.json — deployed via xdg.configFile to
#   each editor's config path. Extensions are managed per-editor since each
#   fork has its own extension host and marketplace integration.
#
#   programs.vscode handles the VSCode binary and its extensions declaratively.
#   Cursor and Antigravity share the settings deployed via xdg.configFile.
#
# EXTENSIONS — TWO TIERS:
#   Tier 1 (nixpkgs): extensions available as pkgs.vscode-extensions.*
#     Managed by Nix — reproducible, no network call at activation time.
#
#   Tier 2 (marketplace): extensions not in nixpkgs, fetched from
#     pkgs.nix-vscode-extensions.vscode-marketplace.Previous approach via
#     Open VSX/ VS Marketplace (via vscode-utils.buildVscodeMarketplaceExtension)
#     Was ruled over due to issues with building (hash mismatches).
#
# MAPLE MONO FONT NOTE:
#   settings.json specifies Maple Mono as the editor font. Not in nixpkgs.
#   To install:
#     1. Download from https://github.com/subframe7536/maple-font/releases
#     2. Place TTF files in configs/fonts/maple-mono/
#     3. Add a home.file entry deploying them to ~/.local/share/fonts/
#     4. Run `fc-cache -f` once after first switch
#   Until then the config falls back to JetBrains Mono (already installed).
#
# SHARED SETTINGS STRATEGY:
#   One settings.json is deployed to VSCode, Cursor, and Antigravity.
#   If editor-specific overrides are needed, add separate xdg.configFile
#   entry that writes only the differing keys — the last writer wins for
#   each key in VSCode's settings merge.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ── nix-vscode-extensions aliases ─────────────────────────────────────────
  # These give us short names to reach the two registries.
  #
  # vscode-marketplace: Microsoft's official registry.
  #   Use for extensions that are exclusive to it (proprietary, AI tools, etc.)
  #
  # open-vsx: The vendor-neutral open-source registry.
  #   Prefer this when an extension is available on both — no Microsoft ToS
  #   concerns, and the extension is byte-for-byte identical in most cases.
  #
  # IMPORTANT: publisher and extension names are ALWAYS fully lowercase
  # in Nix attribute paths, even when the marketplace shows mixed case.
  # e.g. "Prisma" publisher → prisma.prisma, "fwcd" → fwcd.kotlin
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;

  # ── Shared settings.json ──────────────────────────────────────────────────
  sharedSettings = {

    # ── Theme ───────────────────────────────────────────────────────────────────
    # workbench.colorTheme is intentionally absent here.
    # It is set automatically by the catppuccin.vscode HM module in config above,
    # which builds the correct theme string from the flavor/accent options.
    # Setting it here would conflict — do not re-add it.
    #
    # HyDE-era themes — uncomment to switch:
    # "workbench.colorTheme" = "Decayce";              # decaycs.decay
    # "workbench.colorTheme" = "Tokyo Night";          # tokyonight.tokyonight
    # "workbench.colorTheme" = "One Dark Pro";         # zhuangtongfa.material-theme
    # "workbench.colorTheme" = "Dracula";              # dracula-theme.theme-dracula
    # "workbench.colorTheme" = "Gruvbox Dark Hard";    # jdinhlife.gruvbox
    # "workbench.colorTheme" = "Cyberpunk";            # max-ss.cyberpunk
    # "workbench.colorTheme" = "Nord";                 # arcticicestudio.nord-visual-studio-code
    #
    # NOTE: Catppuccin themes are handled separately via the catppuccin/nix flake module (see below).
    #
    # To switch flavour: change catppuccin.vscode.flavor above and rebuild.
    # Available commented-out alternatives kept for reference:
    #
    # "workbench.colorTheme" = "Catppuccin Mocha"; # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Macchiato"; # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Frappé";    # catppuccin.catppuccin-vsc
    # "workbench.colorTheme" = "Catppuccin Latte";     # catppuccin.catppuccin-vsc

    # ── Font ────────────────────────────────────────────────────────────────
    "editor.fontFamily" = "'Maple Mono', 'JetBrainsMono Nerd Font', 'monospace', monospace";
    "editor.fontSize" = 12;
    "editor.fontLigatures" = true;

    # ── Editor Core ─────────────────────────────────────────────────────────
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = false;
    "editor.tabSize" = 2;
    "editor.detectIndentation" = true;
    "editor.wordWrap" = "off";
    "editor.cursorBlinking" = "smooth";
    "editor.cursorSmoothCaretAnimation" = "on";
    "editor.smoothScrolling" = true;
    "editor.linkedEditing" = true;
    "editor.bracketPairColorization.enabled" = true;
    "editor.guides.bracketPairs" = "active";
    "editor.inlineSuggest.enabled" = true;
    "editor.suggestSelection" = "first";
    "editor.renderWhitespace" = "boundary"; # show spaces at line boundaries
    "editor.rulers" = [
      80
      100
    ]; # soft column guides

    # ── Scrollbar ───────────────────────────────────────────────────────────
    "editor.scrollbar.vertical" = "hidden";
    "editor.scrollbar.verticalScrollbarSize" = 0;
    "editor.scrollbar.horizontal" = "auto";
    "editor.overviewRulerBorder" = false;

    # ── Minimap ─────────────────────────────────────────────────────────────
    "editor.minimap.side" = "left";
    "editor.minimap.enabled" = true;
    "editor.minimap.scale" = 1;

    # ── Workbench ───────────────────────────────────────────────────────────
    "workbench.statusBar.visible" = false;
    "workbench.activityBar.location" = "top";
    "workbench.tree.indent" = 16;
    "workbench.tree.renderIndentGuides" = "always";
    "workbench.sideBar.location" = "right";
    "window.menuBarVisibility" = "toggle";
    "workbench.startupEditor" = "none"; # no welcome tab on launch

    # ── Terminal ────────────────────────────────────────────────────────────
    "terminal.external.linuxExec" = "kitty";
    "terminal.explorerKind" = "both";
    "terminal.sourceControlRepositoriesKind" = "both";
    "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
    "terminal.integrated.fontSize" = 12;
    "terminal.integrated.cursorBlinking" = true;
    "terminal.integrated.scrollback" = 10000;
    "terminal.integrated.defaultProfile.linux" = "zsh";

    # ── File Handling ────────────────────────────────────────────────────────
    "files.trimTrailingWhitespace" = true;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "files.autoSave" = "onFocusChange";
    "files.exclude" = {
      "**/.git" = true;
      "**/node_modules" = true;
      "**/__pycache__" = true;
      "**/.venv" = true;
      "**/result" = true;
      "**/.dart_tool" = true;
      "**/.flutter-plugins" = true;
    };

    # ── Explorer ─────────────────────────────────────────────────────────────
    "explorer.confirmDelete" = false;
    "explorer.confirmDragAndDrop" = false;
    "explorer.sortOrder" = "type";

    # ── Git ──────────────────────────────────────────────────────────────────
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableSmartCommit" = true;

    # ── Breadcrumbs ──────────────────────────────────────────────────────────
    "breadcrumbs.enabled" = true;

    # ── Language: Python ─────────────────────────────────────────────────────
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.python";
      "editor.tabSize" = 4;
      "editor.formatOnSave" = true;
    };
    "python.analysis.typeCheckingMode" = "basic";
    "python.analysis.autoImportCompletions" = true;
    "python.terminal.activateEnvironment" = true;

    # ── Language: JavaScript / TypeScript ────────────────────────────────────
    "[javascript]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
    };
    "eslint.validate" = [
      "javascript"
      "javascriptreact"
      "typescript"
      "typescriptreact"
    ];
    "eslint.run" = "onSave";
    # TypeScript: use workspace version if available, fall back to bundled
    "typescript.tsdk" = "node_modules/typescript/lib";
    "typescript.enablePromptUseWorkspaceTsdk" = true;

    # ── Language: JSON ───────────────────────────────────────────────────────
    "[json]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };

    # ── Language: HTML / CSS ─────────────────────────────────────────────────
    "[html]" = {
      "editor.defaultFormatter" = "vscode.html-language-features";
    };
    "[css]" = {
      "editor.defaultFormatter" = "vscode.css-language-features";
    };
    "[scss]" = {
      "editor.defaultFormatter" = "vscode.css-language-features";
    };

    # ── Language: Bash / Shell ───────────────────────────────────────────────
    "[shellscript]" = {
      "editor.defaultFormatter" = "mads-hartmann.bash-ide-vscode";
    };
    "shellcheck.enable" = true;
    "shellcheck.executablePath" = "shellcheck"; # in PATH via home.packages
    "bashIde.shellcheckPath" = "shellcheck";

    # ── Language: Lua ────────────────────────────────────────────────────────
    "[lua]" = {
      "editor.defaultFormatter" = "sumneko.lua";
    };
    # Tell the Lua LSP about Neovim's global API so it doesn't flag vim.* as unknown
    "Lua.workspace.library" = [
      "\${3rd}/luv/library" # luv (libuv bindings)
    ];
    "Lua.workspace.checkThirdParty" = false;
    "Lua.diagnostics.globals" = [ "vim" ]; # suppress "undefined global vim"
    "Lua.runtime.version" = "LuaJIT"; # Neovim uses LuaJIT

    # ── Language: Nix ────────────────────────────────────────────────────────
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.tabSize" = 2;
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd"; # nixd LSP — declared in home.packages
    "nix.serverSettings" = {
      nixd = {
        formatting.command = [ "nixfmt" ]; # nixfmt in home.packages
      };
    };

    # ── Language: Rust ───────────────────────────────────────────────────────
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
    };
    "rust-analyzer.checkOnSave" = true;
    "rust-analyzer.cargo.allFeatures" = true;
    "rust-analyzer.procMacro.enable" = true;

    # ── Language: SQL ────────────────────────────────────────────────────────
    # SQLTools connections are added interactively via the SQLTools panel
    # (they contain credentials — not declared here).
    # Driver format hint: PostgreSQL connection stored in
    # $XDG_CONFIG_HOME/Code/User/settings.json under "sqltools.connections"
    # once you add one via the UI.
    "sqltools.useNodeRuntime" = true;
    "sqltools.autoOpenSessionFiles" = false;

    # ── Language: Flutter / Dart ─────────────────────────────────────────────
    # Flutter SDK path: Home Manager installs flutter to the Nix store.
    # The path below is set dynamically — replace with the actual store path
    # or set it to the flutter binary location after first switch:
    #   `which flutter | xargs dirname | xargs dirname`
    #  e.g /etc/profiles/per-user/cypher-whisperer
    # Alternatively leave unset and let the extension auto-detect.
    # "dart.flutterSdkPath" = "/path/to/flutter";  # set after first switch
    "dart.debugExternalPackageLibraries" = false;
    "dart.debugSdkLibraries" = false;
    "dart.openDevTools" = "flutter";
    "[dart]" = {
      "editor.defaultFormatter" = "Dart-Code.dart-code";
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.rulers" = [ 80 ];
      "editor.selectionHighlight" = false;
      "editor.suggest.snippetsPreventQuickSuggestions" = false;
      "editor.tabCompletion" = "onlySnippets";
      "editor.wordBasedSuggestions" = "off";
    };

    # ── Language: Vue ────────────────────────────────────────────────────────
    "[vue]" = {
      "editor.defaultFormatter" = "vue.volar";
    };

    # ── Language: Svelte ─────────────────────────────────────────────────────
    "[svelte]" = {
      "editor.defaultFormatter" = "svelte.svelte-vscode";
    };

    # ── Language: Arduino ──────────────────────────────────────────────────
    # arduino-cli is the compile/upload backend. The extension resolves it
    # from $PATH — no absolute path needed since arduino-cli is a statically-
    # linked Go binary (no FHS chroot required unlike native .node addons).
    # useArduinoCli must be true — the legacy IDE 1.x builder is not present.
    # Per-workspace board/port settings live in .vscode/arduino.json (auto-
    # generated by the extension on first sketch open — safe to commit).
    "arduino.useArduinoCli" = true;
    "arduino.commandPath" = "arduino-cli";
    "arduino.logLevel" = "info";
    "arduino.clearOutputOnBuild" = true;
    "arduino.defaultBaudRate" = 9600;

    # ── DevOps: Docker ───────────────────────────────────────────────────────
    "[dockerfile]" = {
      "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
    };
    "docker.showStartPage" = false;

    # ── DevOps: Kubernetes ───────────────────────────────────────────────────
    "[yaml]" = {
      "editor.defaultFormatter" = "redhat.vscode-yaml";
    };
    "vs-kubernetes" = {
      "vs-kubernetes.kubectl-path" = "kubectl"; # in PATH via home.packages
    };

    # ────────────────── PHP ───────────────────────────────────────────────────
    # ──────────────────────────────────────────────────────────────────────────────
    # PHP — Intelephense
    # ──────────────────────────────────────────────────────────────────────────────

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

    # ──────────────────────────────────────────────────────────────────────────────
    # PHP — Formatting (PHP-CS-Fixer as sole authority)
    # ──────────────────────────────────────────────────────────────────────────────

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

    # ──────────────────────────────────────────────────────────────────────────────
    # PHP — PHPStan (inline static analysis)
    # ──────────────────────────────────────────────────────────────────────────────

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

    # ──────────────────────────────────────────────────────────────────────────────
    # PHP — Debugging (Xdebug via PHP Debug extension)
    # ──────────────────────────────────────────────────────────────────────────────

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

    # ──────────────────────────────────────────────────────────────────────────────
    # PHP — Test explorer
    # ──────────────────────────────────────────────────────────────────────────────

    # PHP binary for the test runner (used by recca0120.vscode-phpunit).
    "phpunit.php" = "php";

    # Preferred test runner binary resolution order:
    # 1. ${workspaceFolder}/vendor/bin/phpunit  (Composer per-project install)
    # 2. phpunit on system PATH (system-wide fallback from php.nix)
    "phpunit.phpunit" = "\${workspaceFolder}/vendor/bin/phpunit";

    # ──────────────────────────────────────────────────────────────────────────────
    # Blade (Laravel) — only relevant once you start a Laravel project
    # ──────────────────────────────────────────────────────────────────────────────

    "[blade]" = {
      "editor.defaultFormatter" = "shufo.vscode-blade-formatter";
      "editor.formatOnSave" = true;
      "editor.tabSize" = 4;
    };

    # ──────────────────────────────────────────────────────────────────────────────
    # D2
    # ──────────────────────────────────────────────────────────────────────────────
    "d2.layout" = config.cypher-os.apps.productivity.d2.layoutEngine;
    "d2.theme" = config.cypher-os.apps.productivity.d2.themeId;
    "d2.darkTheme" = config.cypher-os.apps.productivity.d2.darkThemeId;
    "d2.pad" = config.cypher-os.apps.productivity.d2.pad;
    # "D2.checkForInstallAtStart" defaults to true and just verifies the CLI
    # is reachable on activation — harmless to leave at default.

    # ── Extension: Better Comments ───────────────────────────────────────────
    "better-comments.tags" = [
      {
        tag = "!";
        color = "#FF2D00";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "?";
        color = "#3498DB";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "//";
        color = "#474747";
        strikethrough = true;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "todo";
        color = "#FF8C00";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
      {
        tag = "*";
        color = "#98C379";
        strikethrough = false;
        underline = false;
        backgroundColor = "transparent";
        bold = false;
        italic = false;
      }
    ];

    # ── Extension: Color Highlight ───────────────────────────────────────────
    "color-highlight.enable" = true;

    # ── Security ─────────────────────────────────────────────────────────────
    "security.workspace.trust.enabled" = false;
    "security.workspace.trust.untrustedFiles" = "newWindow";
    "security.workspace.trust.startupPrompt" = "never";

    # ── Telemetry ────────────────────────────────────────────────────────────
    "telemetry.telemetryLevel" = "off";
    "redhat.telemetry.enabled" = false;

    # ── Extensions ───────────────────────────────────────────────────────────
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
  };

in
{
  config =
    lib.mkIf
      (
        config.cypher-os.apps.editor.enable
        && config.cypher-os.profile.desktop.enable
        && config.cypher-os.apps.editor.vscode.enable
      )
      {
        # ── Catppuccin Theme ────────────────────────────────────────────────────────
        # Configured via the catppuccin/nix HM module (imported in flake.nix).
        # This approach pre-compiles the chosen flavour at derivation time,
        # which is necessary because the extension normally writes its compiled
        # theme JSON to its own directory at activation — impossible in the
        # read-only Nix store.
        #
        # The module automatically adds the patched extension to programs.vscode
        # and sets workbench.colorTheme in userSettings. We therefore must NOT:
        #   - list catppuccin.catppuccin-vsc in programs.vscode extensions (already removed)
        #   - set workbench.colorTheme in sharedSettings (already removed)
        #
        # Flavours: latte (light), frappe, macchiato, mocha (darkest)
        # Accents:  blue, flamingo, green, lavender, maroon, mauve, peach,
        #           pink, red, rosewater, sapphire, sky, teal, yellow
        catppuccin.vscode.profiles.default = {
          enable = true;
          flavor = "mocha"; # current preference
          accent = "mauve"; # adjust to taste
        };

        # ── VSCode ──────────────────────────────────────────────────────────────────
        programs.vscode = {
          enable = true;

          # mutableExtensionsDir = false: prevents VSCode from writing to the
          # extensions directory at runtime. All extensions come from Nix.
          # Set to true if you want to install extensions manually alongside
          # the Nix-managed ones (useful while evaluating new extensions).
          #
          # Required by the workaround for home-manager regression b593765 (Feb 1, 2026,
          # "vscode: fix extension path for antigravity"). That commit changed how
          # .extensions-immutable.json is generated, which caused VS Code to mark all
          # Nix-managed extensions as obsolete on load — extensions were correctly
          # symlinked but invisible to the editor.
          #
          # The workaround (HM issue #8793) requires extensions at the top-level
          # programs.vscode.extensions key rather than profiles.default.extensions.
          # That key only takes effect when mutableExtensionsDir = false.
          #
          # Revert to true (and move extensions back to profiles.default.extensions)
          # once upstream resolves: https://github.com/nix-community/home-manager/issues/8793
          mutableExtensionsDir = false;

          # userSettings: written to VSCode's settings.json.
          # Shared settings are merged here.
          profiles.default.userSettings = sharedSettings;

          # Extensions are intentionally declared at the TOP LEVEL (not profiles.default.extensions)
          # as a workaround for the home-manager regression introduced in commit b593765 (Feb 2026),
          # which broke extension loading when using profiles.default.extensions. HM routes this
          # to the default profile internally. A deprecation warning is emitted at build time —
          # it is cosmetic and can be ignored until upstream reverts or properly fixes the regression.
          # Track: https://github.com/nix-community/home-manager/issues/8793
          #
          # Declared at programs.vscode.extensions (top-level) instead of
          # programs.vscode.profiles.default.extensions — workaround for HM regression
          # b593765 (Feb 2026). HM still routes this to the default profile internally.
          # A build-time deprecation warning is emitted; it is cosmetic, ignore it:
          #   trace: warning: The option `programs.vscode.extensions' ... has been renamed to
          #   `programs.vscode.profiles.default.extensions'.
          # Track: https://github.com/nix-community/home-manager/issues/8793
          extensions =
            with pkgs.vscode-extensions;
            [
              # ── Theme ────────────────────────────────────────────────────────────
              # Uncomment to install alongside (switch via workbench.colorTheme above):
              # enkia.tokyo-night
              #
              # NOTE: Catppuccin themes are handled separately via the catppuccin/nix flake module.
              #       (see above)
              #
              # catppuccin.catppuccin-vsc
              # dracula-theme.theme-dracula
              # zhuangtongfa.material-theme   # One Dark Pro
              # jdinhlife.gruvbox
              # arcticicestudio.nord-visual-studio-code

              # ── General Productivity ─────────────────────────────────────────────
              aaron-bond.better-comments
              naumovs.color-highlight
              christian-kohler.path-intellisense
              christian-kohler.npm-intellisense
              visualstudioexptteam.vscodeintellicode
              visualstudioexptteam.intellicode-api-usage-examples

              # ── Markdown ────────────────────────────────────────────────────────────────────
              yzhang.markdown-all-in-one # TOC, list editing, shortcuts
              davidanson.vscode-markdownlint # Lint enforcement
              shd101wyy.markdown-preview-enhanced # Rich rendering (Mermaid, math, themes)
              bierner.markdown-mermaid # Mermaid in native preview
              #bierner.markdown-preview-github-styling # Optional: GitHub-styled native preview

              # ── Web / HTML / CSS ──────────────────────────────────────────────────
              ecmel.vscode-html-css
              ritwickdey.liveserver

              # ── Web: Prisma ───────────────────────────────────────────────────────────────
              # Syntax highlighting, formatting, auto-completion, and jump-to-definition
              # for .prisma schema files. In nixpkgs — no marketplace fetch needed.
              prisma.prisma

              # ── JavaScript / TypeScript ───────────────────────────────────────────
              dbaeumer.vscode-eslint

              # ── Vue / Svelte ──────────────────────────────────────────────────────
              vue.volar # Vue 3 official language support
              svelte.svelte-vscode # Svelte language support

              # ── SVG ──────────────────────────────────────────────────────────────
              jock.svg

              # ── Python ───────────────────────────────────────────────────────────
              ms-python.python
              ms-python.vscode-pylance
              ms-python.debugpy
              njpwerner.autodocstring
              batisteo.vscode-django
              wholroyd.jinja

              # ── Bash / Shell ─────────────────────────────────────────────────────
              mads-hartmann.bash-ide-vscode # bash LSP (bash-language-server)
              timonwong.shellcheck # ShellCheck linting integration

              # ── Lua ───────────────────────────────────────────────────────────────
              sumneko.lua # Lua LSP — essential for CypherIDE config editing

              # ── Nix ───────────────────────────────────────────────────────────────
              # jnoortheen.nix-ide is referenced in language settings above.
              # Adding it here makes the formatter actually available.
              jnoortheen.nix-ide # Nix language support + nixd LSP integration

              # ── Rust ─────────────────────────────────────────────────────────────
              rust-lang.rust-analyzer
              serayuzgur.crates # Cargo.toml dependency helper
              tamasfe.even-better-toml # TOML syntax + validation
              vadimcn.vscode-lldb # LLDB debugger for Rust/C/C++

              # ── C / C++ ──────────────────────────────────────────────────────────
              ms-vscode.cpptools
              ms-vscode.cpptools-extension-pack
              ms-vscode.cmake-tools
              twxs.cmake

              # ── Vim keybindings ──────────────────────────────────────────────────
              #vscodevim.vim

              # ── Flutter / Dart ────────────────────────────────────────────────────
              dart-code.flutter # Flutter tooling, hot reload, device management
              dart-code.dart-code # Dart language support (flutter depends on this)

              # ── Mobile: React Native ──────────────────────────────────────────────
              # msjsdiag.vscode-react-native is in marketplace tier (not in nixpkgs)

              # ── DevOps: Docker ────────────────────────────────────────────────────
              ms-azuretools.vscode-docker
              ms-vscode-remote.remote-containers
              # ── DevOps: Containers  ───────────────────────────────────────────────
              ms-azuretools.vscode-containers
              ms-vscode-remote.remote-containers

              # ── DevOps: Kubernetes ────────────────────────────────────────────────
              ms-kubernetes-tools.vscode-kubernetes-tools
              redhat.vscode-yaml # YAML support — used by k8s manifests, GH Actions

              # ── DevOps: CI/CD ─────────────────────────────────────────────────────
              github.vscode-github-actions
            ]
            ++ [
              # ── Tier 2: nix-vscode-extensions (marketplace/open-vsx) ──────────────────
              # Extensions not packaged in nixpkgs, sourced from nix-community/nix-vscode-extensions.
              # No sha256 needed — hashes are pre-computed in the flake's JSON cache.
              # To update all of these to their latest versions: nix flake update nix-vscode-extensions
              #
              # Naming convention: vscMkt.<publisher>.<extension-name> (all lowercase)
              # Check Open VSX first (openVsx.*) — prefer it over vscMkt when available.

              # ── AI / Code Review ───────────────────────────────────────────────────────
              vscMkt.coderabbit.coderabbit-vscode
              vscMkt.openai.chatgpt

              # ── Code Runner ────────────────────────────────────────────────────────────
              vscMkt.formulahendry.code-runner

              # ── Theme ──────────────────────────────────────────────────────────────────
              # Catppuccin handled separately via catppuccin/nix flake module (see below)
              vscMkt.decaycs.decay
              vscMkt.nishantg96.dark-decay-pro

              # ── HTML ───────────────────────────────────────────────────────────────────
              vscMkt.george-alisson.html-preview-vscode
              vscMkt.sidthesloth.html5-boilerplate
              vscMkt.riazxrazor.html-to-jsx

              # ── CSS ────────────────────────────────────────────────────────────────────
              vscMkt.phoenisx.cssvar

              # ── SVG ────────────────────────────────────────────────────────────────────
              vscMkt.henoc.svgeditor
              vscMkt.sidthesloth.svg-snippets

              # ── JavaScript / TypeScript / React ────────────────────────────────────────
              vscMkt.xabikos.javascriptsnippets
              vscMkt.xabikos.reactsnippets
              vscMkt.dsznajder.es7-react-js-snippets
              vscMkt.burkeholland.simple-react-snippets
              vscMkt.ms-vscode.vscode-typescript-next
              vscMkt.jasonnutter.search-node-modules
              vscMkt.infeng.vscode-react-typescript
              vscMkt.msjsdiag.vscode-react-native
              vscMkt.jawandarajbir.react-vscode-extension-pack

              # ── Python ─────────────────────────────────────────────────────────────────
              vscMkt.donjayamanne.python-environment-manager
              vscMkt.kevinrose.vsc-python-indent

              # ── Rust ───────────────────────────────────────────────────────────────────
              vscMkt.dustypomerleau.rust-syntax
              # Nix attribute names cannot start with a digit.
              # Use the string-subscript form: attrset."string-key" instead of attrset.identifier
              vscMkt."1yib".rust-bundle
              vscMkt.swellaby.rust-pack

              # ── Assembly ───────────────────────────────────────────────────────────────
              # Nix attribute names cannot start with a digit.
              # Use the string-subscript form: attrset."string-key" instead of attrset.identifier
              vscMkt."13xforever".language-x86-64-assembly

              # ── SQL ────────────────────────────────────────────────────────────────────
              vscMkt.mtxr.sqltools
              vscMkt.mtxr.sqltools-driver-pg

              # ── Mobile: Kotlin ─────────────────────────────────────────────────────────
              # Not in nixpkgs — sourced from nix-vscode-extensions.
              vscMkt.fwcd.kotlin

              # ── DevOps: Docker Compose ─────────────────────────────────────────────────
              # p1c2u's Docker Compose extension — not in nixpkgs.
              vscMkt.p1c2u.docker-compose

              # ── DevOps: Docker Extension Pack (Jun Han) ────────────────────────────────
              # The pack itself; ms-azuretools.vscode-docker is already in Tier 1 above.
              vscMkt.formulahendry.docker-extension-pack

              # ── AI: Claude Code ────────────────────────────────────────────────────────
              # Anthropic's Claude Code extension — not in nixpkgs.
              vscMkt.anthropic.claude-code

              # ── IoT: Arduino Dev ────────────────────────────────────────────────────────
              # Arduino Community Edition — the maintained successor to the deprecated
              # Microsoft arduino extension (ms-vscode.vscode-arduino). The Microsoft
              # extension does not support arduino-cli or Arduino IDE 2.x properly.
              # This extension delegates all compile/upload work to arduino-cli (in PATH)
              # so it does not require vscode.fhs. If the serial monitor bridge fails
              # with a dynamic linker error at runtime, switch package to pkgs.vscode.fhs
              # (one-line change — all other config carries over unchanged).
              #
              # Microsoft's original extension (ms-vscode.vscode-arduino) was removed from
              # the marketplace on October 1, 2024 and the repository archived. The
              # community-maintained fork lives under the vscode-arduino GitHub organisation,
              # hence the publisher name matching the org
              vscMkt.vscode-arduino.vscode-arduino-community

              # ── Caddy ──────────────────────────────────────────────────────────────────
              vscMkt.matthewpi.caddyfile-support

              # ──────────────────────────────────────────────────────────────────────────────
              # PHP — Core language intelligence
              # ──────────────────────────────────────────────────────────────────────────────

              # PHP Intelephense — primary language server
              # ──────────────────────────────────────────────────────────────────────────────
              # The backbone of PHP development in VSCode. Provides:
              #   • Intelligent completion (functions, classes, methods, variables)
              #   • Go-to-definition and find-all-references across the full project
              #   • Real-time diagnostics (type errors, undefined symbols)
              #   • Hover documentation, signature help
              #   • Code folding, document symbols, workspace indexing
              #
              # §INTELEPHENSE-VS-PHPTOOLS
              # This module installs Intelephense as the sole PHP language server.
              # DEVSense phptools-vscode (DEVSENSE.phptools-vscode) is an alternative
              # that offers deeper IntelliSense for large Symfony/Laravel enterprise
              # codebases and some additional Blade-aware features. It was evaluated
              # and intentionally excluded because:
              #   1. It competes directly with Intelephense — running both causes
              #      duplicate diagnostics, conflicting completions, and save-time lag.
              #   2. Its full feature set requires a paid license; the free tier offers
              #      marginal gains over Intelephense for projects at CypherOS scale.
              #   3. Intelephense's free tier covers 100% of DevLog's and most
              #      Laravel/Symfony projects' daily development needs.
              #
              # If you ever outgrow Intelephense on a very large enterprise codebase:
              #   1. Remove bmewburn.vscode-intelephense-client from this list.
              #   2. Uncomment DEVSENSE.phptools-vscode below.
              #   3. Remove the intelephense.* settings from userSettings (Section B).
              #   4. Update "[php]".editor.defaultFormatter to "DEVSENSE.phptools-vscode".
              #
              # DEVSENSE alternative (commented out — see rationale above):
              # vscMkt."DEVSENSE".phptools-vscode
              vscMkt.bmewburn.vscode-intelephense-client

              # PHP Debug — Xdebug DAP client
              # ──────────────────────────────────────────────────────────────────────────────
              # Bridges Xdebug (installed via php.nix buildEnv) to VSCode's native
              # debugger UI. Enables:
              #   • Breakpoints (click left gutter or F9)
              #   • Step over / step into / step out
              #   • Variable inspection and watch expressions
              #   • Call stack navigation
              #   • Conditional breakpoints and logpoints
              #
              # Requires a launch.json in the project. VSCode will offer to generate one
              # when you open the Run & Debug panel (Ctrl+Shift+D) on a PHP project.
              # The generated "Listen for Xdebug" configuration works out of the box with
              # the Xdebug settings in php.nix (port 9003, idekey VSCODE).
              vscMkt.xdebug.php-debug

              # ──────────────────────────────────────────────────────────────────────────────
              # PHP — Static analysis & code style
              # ──────────────────────────────────────────────────────────────────────────────

              # PHPStan — inline static analysis diagnostics
              # ──────────────────────────────────────────────────────────────────────────────
              # Surfaces PHPStan findings (type errors, undefined methods, dead code)
              # as inline squiggles and Problems panel entries as you type.
              # Reads phpstan.neon from the project root for level and configuration.
              #
              # NOTE: Verify the publisher ID at update time. The "swordev" publisher is
              # current as of mid-2026, but PHPStan-related extensions have changed
              # publisher accounts before. Run `nix flake update` on your
              # nix-vscode-extensions input and grep the result for "phpstan" to confirm.
              vscMkt.swordev.phpstan

              # PHP CS Fixer — format on save
              # ──────────────────────────────────────────────────────────────────────────────
              # Calls the php-cs-fixer binary (installed via php.nix) on save.
              # Configured to use @PSR12 ruleset by default (see §VSCODE-FORMATTER below).
              # For Laravel projects, swap formatter to open-southeners.laravel-pint.
              vscMkt.junstyle.php-cs-fixer

              # PHPDoc Blocker — documentation generation
              # ──────────────────────────────────────────────────────────────────────────────
              # Type `/**` above a function/class/property and press Enter to generate
              # a fully populated PHPDoc block with @param, @return, and @throws tags.
              # Saves repetitive boilerplate when documenting DevLog and framework code.
              vscMkt.neilbrayfield.php-docblocker

              # ──────────────────────────────────────────────────────────────────────────────
              # PHP — Testing
              # ──────────────────────────────────────────────────────────────────────────────

              # PHPUnit Test Explorer (recca0120)
              # ──────────────────────────────────────────────────────────────────────────────
              # Integrates PHPUnit and Pest with VSCode's native Test Explorer UI:
              #   • Auto-discovers tests from phpunit.xml / phpunit.xml.dist
              #   • Run individual tests, files, or full suite from the sidebar
              #   • CodeLens indicators above each test method
              #   • Supports PHPUnit 7–12 and Pest
              #   • Reloads tests dynamically on composer.lock changes
              #   • Parallel test execution via ParaTest (if installed)
              #
              # NOTE: verify publisher is `recca0120` at install time — the Test Explorer
              # space has seen republishing under different accounts.
              vscMkt.recca0120.vscode-phpunit

              # Pest Snippets (dansysanalyst)
              # ──────────────────────────────────────────────────────────────────────────────
              # Snippet set for Pest's DSL (it(), test(), expect(), beforeEach(), etc.).
              # Pest is now the Laravel-ecosystem default and works in vanilla PHP too.
              # Zero config required — snippets are available immediately for .php files.
              vscMkt.dansysanalyst.pest-snippets

              # ──────────────────────────────────────────────────────────────────────────────
              # PHP — Framework-specific (future-proof; ready when you need them)
              # ──────────────────────────────────────────────────────────────────────────────

              # Official Laravel extension (Laravel team)
              # ──────────────────────────────────────────────────────────────────────────────
              # As of 2026 this is the consolidated, official Laravel extension — it
              # replaced the fragmented community extensions (Laravel Extra Intellisense,
              # Laravel Goto View, Laravel Artisan, etc.) that previously required
              # installing separately. Provides:
              #   • Model, config, route, and view auto-completion
              #   • Click-to-definition for route names, view paths, config keys
              #   • Artisan command runner from the command palette
              #   • Blade directive IntelliSense (complements Blade extension below)
              #
              # Activate when you start a Laravel project. No harm in having it installed
              # in the meantime; it only activates on Laravel project detection.
              vscMkt.laravel.vscode-laravel

              # Blade syntax and snippets (onecentlin)
              # ──────────────────────────────────────────────────────────────────────────────
              # Blade template syntax highlighting, code folding, and common directive
              # snippets (@foreach, @if, @extends, @section, @component, etc.).
              # Pairs with the official Laravel extension above.
              vscMkt.onecentlin.laravel-blade

              # Blade Formatter (shufo)
              # ──────────────────────────────────────────────────────────────────────────────
              # Auto-formats Blade templates with configurable indent and style rules.
              # Activate format-on-save for .blade.php files once you start using Laravel.
              # Config: .bladeformatter.json in project root.
              vscMkt.shufo.vscode-blade-formatter

              # Laravel Pint (open-southeners)
              # ──────────────────────────────────────────────────────────────────────────────
              # Pint is PHP-CS-Fixer with Laravel's opinionated house ruleset — it ships
              # pre-configured in new Laravel projects (laravel/pint in composer.json).
              # This extension calls the project-local `vendor/bin/pint` binary.
              #
              # WHEN WORKING IN LARAVEL: set "[php]".editor.defaultFormatter to
              # "open-southeners.laravel-pint" instead of "junstyle.php-cs-fixer".
              # Both are installed; the formatter switch is per-project (workspace settings).
              vscMkt.open-southeners.laravel-pint

              # Symfony snippets
              # ──────────────────────────────────────────────────────────────────────────────
              # Common Symfony boilerplate: service definitions, controller scaffolding,
              # console command stubs, Twig directives, etc.
              #
              # NOTE: Symfony VSCode tooling has a smaller publisher pool than Laravel's —
              # verify the publisher ID (julien-deramond is current as of mid-2026) with
              # `nix flake update` before committing this line.
              # vscMkt.julien-deramond.symfony-snippets  # uncomment when doing Symfony work

              # ──────────────────────────────────────────────────────────────────────────────
              # DotEnv
              # ──────────────────────────────────────────────────────────────────────────────

              # .env syntax highlighting (mikestead)
              # ──────────────────────────────────────────────────────────────────────────────
              # Syntax highlighting and basic validation for .env files. Applies to:
              # DevLog config files, Laravel's .env, Symfony's .env.local, and any
              # key=value environment file in any project.
              vscMkt.mikestead.dotenv

              # ────── D2 Diagramming ─────────────────────────────────────────────────────────
              vscMkt.terrastruct.d2
            ];
        };
        # ── Shared Settings Deployment ──────────────────────────────────────────────
        # Deploy the same settings.json to Cursor and Antigravity.
        # Both editors respect the XDG config path pattern.
        # The JSON is generated from sharedSettings (same source as VSCode above).
        xdg.configFile."Cursor/User/settings.json".text = builtins.toJSON sharedSettings;

        xdg.configFile."antigravity/User/settings.json".text = builtins.toJSON sharedSettings;
      };
}
