# modules/apps/productivity/obsidian.nix
#
# Declarative Obsidian configuration via Home Manager's programs.obsidian module.
#
# ARCHITECTURE
# ─────────────
# HM writes symlinks into <vault>/.obsidian/ from the Nix store. Obsidian cannot
# write back to those files at runtime — any plugin that persists to data.json must
# have its settings declared here under `settings` (mapped to its data.json).
#
# Any plugin you want active MUST be declared here.
# Do not mix declarative and manual plugin management for the same vault.
#
# COMMUNITY PLUGINS
# ──────────────────
# communityPlugins accepts a list of Nix derivations (packages), not plain strings.
# Each plugin is a stdenv.mkDerivation that fetches the plugin source from GitHub.
# There is no pkgs.obsidianPlugins.* attribute set in nixpkgs — plugins are
# defined locally as callPackage expressions in modules/apps/productivity/obsidian-plugins/.
#
# CATPPUCCIN THEMING
# ───────────────────
# catppuccin/nix DOES support Obsidian. When catppuccin.enable = true is set
# globally and programs.obsidian.enable = true, catppuccin/nix automatically
# injects a Catppuccin theme derivation into programs.obsidian.defaultSettings.themes.
#
# Do NOT also declare defaultSettings.themes manually — the HM obsidian module
# uses findSingle over the themes list and throws "Only one theme can be enabled
# at a time." if more than one entry has enable = true.
#
# Theme management is therefore fully delegated to catppuccin/nix. Flavor and
# accent selection is handled by the Style Settings community plugin via its
# data.json settings (see communityPlugins below). Without Style Settings, the
# Catppuccin options panel in Preferences → Appearance is empty and the theme
# renders with its default palette only.

{
  config,
  pkgs,
  lib,
  ...
}:

let

  # ── Plugin helper ────────────────────────────────────────────────────────────
  # Inline mkDerivation for small plugins. For larger ones, move to a
  # separate file under obsidian-plugins/ and use pkgs.callPackage.
  #
  # Obsidian community plugins are Electron extensions loaded at runtime via
  # Node's require(): each plugin is a directory three files
  #  main.js - compiled JS bundle (actual plugin code)
  #  manifest.json - plugin metadat (id, version, minAppVersion, etc.)
  #  styles.css - Opional UI styles
  #
  #  Obsidian loads main.js at runtime via Node's require().
  # The compiled main.js is NOT present in the plugin's git repository — it is a
  # build artifact published to GitHub Releases. Fetching the source tree via
  # fetchFromGitHub therefore produces a derivation with no main.js, and Obsidian
  # throws "failed to load plugin" silently at startup despite the symlink existing.
  #
  # Each file is fetched individually from the release page with fetchurl.
  # stylesHash is optional — pass null for plugins that don't ship styles.css.
  #
  # To get hashes for a new plugin or version:
  #   nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/main.js
  #   nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/manifest.json
  #   nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/styles.css
  # Convert raw base32 output to SRI format:
  #   nix hash convert --hash-algo sha256 --to sri <raw-hash>
  mkPlugin =
    {
      pname,
      version,
      owner,
      repo,
      mainJsHash,
      manifestHash,
      stylesHash ? null,
    }:
    pkgs.stdenv.mkDerivation {
      inherit pname version;
      dontUnpack = true;
      dontBuild = true;
      installPhase =
        let
          mainJs = pkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/releases/download/${version}/main.js";
            hash = mainJsHash;
          };
          manifest = pkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/releases/download/${version}/manifest.json";
            hash = manifestHash;
          };
        in
        ''
          mkdir -p $out
          cp ${mainJs}   $out/main.js
          cp ${manifest} $out/manifest.json
          ${lib.optionalString (stylesHash != null) ''
            cp ${
              pkgs.fetchurl {
                url = "https://github.com/${owner}/${repo}/releases/download/${version}/styles.css";
                hash = stylesHash;
              }
            } $out/styles.css
          ''}
        '';
    };

  # ── Theme helper ─────────────────────────────────────────────────────────────
  # Letting catppuccin/nix take control over theming as it should
  #
  # mkTheme =
  #   {
  #     pname,
  #     version,
  #     owner,
  #     repo,
  #     rev ? version,
  #     hash,
  #   }:
  #   pkgs.stdenv.mkDerivation {
  #     inherit pname version;
  #     src = pkgs.fetchFromGitHub {
  #       inherit
  #         owner
  #         repo
  #         rev
  #         hash
  #         ;
  #     };
  #     dontBuild = true;
  #     installPhase = ''
  #       mkdir -p $out
  #       cp manifest.json $out/
  #       [ -f obsidian.css ] && cp obsidian.css $out/
  #     '';
  #   };

  # ── Plugin packages ──────────────────────────────────────────────────────────
  # Hashes are for compiled release assets fetched from GitHub Releases.
  # To update after nix flake update, re-run nix-prefetch-url for each file at
  # the new version tag, then convert with:
  #   nix hash convert --hash-algo sha256 --to sri <raw-hash>

  pluginStyleSettings = mkPlugin {
    pname = "obsidian-style-settings";
    version = "1.0.9";
    owner = "mgmeyers";
    repo = "obsidian-style-settings";
    mainJsHash = "sha256-GCirqs2rTFV4twWmJcWFswUS+O+tTHz8WhjnDMNVdGg=";
    manifestHash = "sha256-nP/cIM8qoTVIIOAFC2lLD5tXZEbj1dRKNq6LAYflv7g=";
    stylesHash = "sha256-7nk30r5QZTqJzLMK5fBXKyNQfVt/EyjQBScaNjB1v9g=";
  };

  pluginObsidianGit = mkPlugin {
    pname = "obsidian-git";
    version = "2.32.1";
    owner = "Vinzent03";
    repo = "obsidian-git";
    mainJsHash = "sha256-S/dWc0TeclfCEQwoLRgMddZTjTKIdrKBFfYewls9qRU=";
    manifestHash = "sha256-j/iozkUHdWlnfFrqt7JsQvuNF9HQLU4ZmgY0t306JF8=";
    stylesHash = "sha256-Yao7ujEWP4kxzbhphGFPBy7atgE1uApuRe28zmB9MwA=";
  };

  pluginDataview = mkPlugin {
    pname = "dataview";
    version = "0.5.67";
    owner = "blacksmithgu";
    repo = "obsidian-dataview";
    mainJsHash = "sha256-YyYDb51+5z2yJtXKUeB3Sx4YG+gJZWcn/xvQSDovY2s=";
    manifestHash = "sha256-P1XnPUPruazBaKbXsguFS29EXcvoVwWIVLHbhLgkqBw=";
    stylesHash = "sha256-z8T/vXpQffcNan0khWGks5v2y1RbuEeKWoCsju4YxGw=";
  };

  pluginTemplater = mkPlugin {
    pname = "templater-obsidian";
    version = "2.9.0";
    owner = "SilentVoid13";
    repo = "Templater";
    mainJsHash = "sha256-XgFb/QNzwwG/EImvGKdg6m52ObKNDrON6lAmd7pBkjs=";
    manifestHash = "sha256-yVvGyxFPW8Bw0ZMWnvTSniaCnY+ry5AipoxJ6Ew9KiI=";
    stylesHash = "sha256-Gg1JMSz6ZWamB6HkN6VyoAsWQ79EOpNI2Wpo12s9mas=";
  };

  pluginRecentFiles = mkPlugin {
    pname = "recent-files-obsidian";
    version = "1.7.4";
    owner = "tgrosinger";
    repo = "recent-files-obsidian";
    mainJsHash = "sha256-Ro5wlq6PpwwUnkSEgxpWvZU9JAD6EDYklxFKReHckls=";
    manifestHash = "sha256-nc6Z5vD6zBonFVc6ybK0Rvy1XZ8wwwlOkGyCCovQ6lQ=";
    # no styles.css in this release
  };

  pluginCalendar = mkPlugin {
    pname = "calendar";
    version = "1.5.10";
    owner = "liamcain";
    repo = "obsidian-calendar-plugin";
    mainJsHash = "sha256-f7M56c+f2+WoAforirhbNmtbN3f70ZPLyHKLwncR0SU=";
    manifestHash = "sha256-8+lYEzhkhRK6oS1bRYSQ9/02eRj3vba9hhcc5Xvn0Is=";
    # no styles.css in this release
  };

  # CANVAS RELATED
  pluginAdvancedCanvas = mkPlugin {
    pname = "advanced-canvas";
    version = "6.2.1";
    owner = "Developer-Mike";
    repo = "obsidian-advanced-canvas";
    mainJsHash = "sha256-J2wnJ5P6oVkxXf+s9SdpfcuV4KDeNswy2aipZfFqWr8=";
    manifestHash = "sha256-WzUcGP0bFHokKXghYbEq4HfOVM6oOs/mqtABjoNUNyw=";
    stylesHash = "sha256-WBiZf6PInCdKzJpH9yTrlJGNZnHG9JnYXXN2aW52PAs=";
  };

  pluginOptimizeCanvasConnections = mkPlugin {
    pname = "optimize-canvas-connections";
    version = "1.0.0";
    owner = "felixchenier";
    repo = "obsidian-optimize-canvas-connections";
    mainJsHash = "sha256-sadDBFF7K6ENah9b2DQedM28TIugCqTBcMp5m1f0F/M=";
    manifestHash = "sha256-0z5SO0QjQw86i0T4s5usT6pfudq+Esa5uoYK9wDzjcI=";
    # no styles.css in releases
  };

  pluginCanvasFilter = mkPlugin {
    pname = "obsidian-canvas-filter";
    version = "0.9.4";
    owner = "IKoshelev";
    repo = "Obsidian-Canvas-Filter";
    mainJsHash = "sha256-b2y/XCRr3V413n/D5B//cJ0WbSbw188YDorRb7h7UMI=";
    manifestHash = "sha256-ZtgWYcJ/wcnXo+/wE1TfAQ1tSuvWq2WZTbp/mC4LtPc=";
    stylesHash = "sha256-NNq6X4QF/nehZymrFYosSvXBk008n+N2/Yw59bxrryw=";
  };

  pluginD2 = mkPlugin {
    pname = "d2-obsidian";
    version = "1.1.4";
    owner = "terrastruct";
    repo = "d2-obsidian";
    mainJsHash = "sha256-lYD4oxlGYk0+DaQO9zidd7Aey8oBTyrJ2lPf/OxzY80=";
    manifestHash = "sha256-P9rRA18GNmoVEabILnhASOlhWKkJPWB0BASWNWmRhzg=";
    stylesHash = "sha256-j+WA+FnGzyrW+81gC9ObWfkJCWzogRWNDFjRfB+zYYU=";
  };

  # ── Theme packages ───────────────────────────────────────────────────────────
  # Letting catppuccin/nix take control over theming as it should
  #
  # themeCatppuccin = mkTheme {
  #   pname = "catppuccin";
  #   version = "2.0.4";
  #   owner = "catppuccin";
  #   repo = "obsidian";
  #   rev = "v2.0.4";
  #   hash = "sha256-fbPkZXlk+TTcVwSrt6ljpmvRL+hxB74NIEygl4ICm2U=";
  # };

in

{
  config =
    lib.mkIf
      (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.obsidian.enable)
      {

        programs.obsidian = {
          enable = true;
          package = pkgs.obsidian;

          # defaultSettings apply to all vaults. Vault-specific settings.* override these.
          # defaultSettings only has the typed sub-options the module explicitly defines:
          # (appearance, app, corePlugins, communityPlugins, themes, cssSnippets, hotkeys, extraFiles).
          defaultSettings = {
            appearance = {
              # Catppuccin community theme.
              # Letting catppuccin/nix take control over theming as it should
              #
              # "cssTheme" = "Catppuccin";

              # Font Management.
              # Note textFontFamily — Obsidian has three separate font slots: interface,
              # text (body), and monospace. If you only set two, the third resets
              # to system default.
              "interfaceFontFamily" = "Courier"; # UI font
              "monospaceFontFamily" = "Courier"; # code/monospace font
              "textFontFamily" = "Courier"; # reading/editor body font
              "baseFontSize" = 14;

              # Theme mode. Obsidian respects the OS setting when set to false/unset;
              # force dark explicitly if you want to guarantee Mocha.
              # "theme" = "obsidian";  # "obsidian" = dark, "moonstone" = light
            };

            # ── App settings ───────────────────────────────────────────────────────
            app = {
              # ── Reading & editor behaviour ─────────────────────────────────────────────
              # Constrains line width in reading/source view — reduces eye-tracking fatigue on wide monitors.
              "readableLineLength" = true; # constrain line width in reading mode

              # Hides line numbers — cleaner prose environment; re-enable if you ever do heavy structural editing.
              "showLineNumber" = false;

              # Opens files in Live Preview by default — immediate rendered feedback without a split pane.
              "defaultViewMode" = "live"; # source | preview | live-preview

              # Enables the hybrid source+preview editor engine; required for defaultViewMode = "live".
              "livePreview" = true;

              # Indentation width — aligns with your repo and devenv tab conventions.
              "tabSize" = 2;

              # Uses spaces rather than hard tab characters — consistent with tabSize above.
              "useTab" = false;

              # Collapses indented list items — useful in long structured notes; toggle per note as needed.
              "foldIndent" = true;

              # Collapses headings on open — reduces visual noise in long ADRs and runbooks.
              "foldHeading" = false;

              # Hides YAML frontmatter block in reading mode — cleaner output for prose-heavy notes.
              "showFrontmatter" = false;

              # Single newline renders as a line break (GFM-compatible) — keeps repo docs portable across renderers.
              "strictLineBreaks" = false;

              # Enables spell checking — useful for journal and prose entries across all vault concerns.
              "spellcheck" = true;

              # Spell check language set — extend if your vault spans multiple written languages.
              "spellcheckLanguages" = [ "en" ];

              # Auto-indents continuation of list items on Enter — prevents manual re-indenting in nested lists.
              "smartIndentList" = true;

              # Converts pasted HTML to Markdown on paste — reduces cleanup when pulling content from browsers.
              "autoConvertHtml" = true;

              # Vim keybindings — disabled; toggle if modal editing ever becomes preferable.
              "vimMode" = false;

              # Canvas: snap cards to grid by default — cleaner spatial layout, especially
              # for research boards where structure matters. Toggle off per canvas at runtime.
              "canvasSnap" = true;

              # ── Links & navigation ──────────────────────────────────────────────────────

              # Writes standard Markdown links instead of [[wikilinks]] — critical for portability outside Obsidian.
              "useMarkdownLinks" = true;

              # Relative link paths — keeps links valid in any renderer (GitHub, mdBook, VSCode preview).
              "newLinkFormat" = "relative";

              # Auto-updates links when a file is renamed — prevents silent broken references across the vault.
              "alwaysUpdateLinks" = true;

              # Opens new tabs adjacent to the active one — preserves spatial context while navigating.
              "openNextToActiveLeaf" = true;

              # New tab steals focus on open — direct navigation flow without manual click-to-focus.
              "focusNewTab" = true;

              # Allows Obsidian to traverse symlinks into directories outside the vault root.
              "followSymlinks" = true;

              # ── File watcher exclusions ──────────────────────────────────────────────────
              # Applied during vault traversal at startup — prevents Obsidian from placing
              # inotify watches on directories that either contain permission-restricted
              # files (e.g. .git/objects/pack at 444) or would generate excessive noise.
              #
              # Matches against path *components* (substring match on each directory name).
              # A filter of ".git" blocks any directory named exactly ".git" at any depth.
              #
              # Sources:
              #   - ignore-by-default (nodemon/AVA canonical list)
              #   - standard .gitignore templates per language ecosystem
              #   - NixOS/devenv specific artifacts
              "userIgnoreFilters" = [
                # ── Version control ──────────────────────────────────────────────────────
                ".git" # Git internals — pack objects are 444 read-only; EACCES root cause

                # ── Node / JavaScript / TypeScript ───────────────────────────────────────
                "node_modules" # npm/yarn/pnpm deps — can contain thousands of .md files
                ".yarn" # Yarn PnP cache and install state
                "bower_components" # Legacy Bower packages (unlikely but defensive)
                ".nyc_output" # nyc/Istanbul coverage raw data
                ".sass-cache" # node-sass compilation cache
                "dist" # Compiled/bundled output (TS, Vite, webpack, etc.)
                "build" # Generic build output dir
                ".next" # Next.js build cache and output
                ".nuxt" # Nuxt build cache
                ".svelte-kit" # SvelteKit build output
                ".turbo" # Turborepo cache
                ".parcel-cache" # Parcel bundler cache
                ".cache" # Generic cache dir (Babel, Gatsby, etc.)
                "coverage" # Jest/Vitest/Istanbul HTML coverage reports

                # ── PHP / Composer ───────────────────────────────────────────────────────
                "vendor" # Composer packages — can be enormous

                # ── Python ───────────────────────────────────────────────────────────────
                "__pycache__" # Compiled bytecode (.pyc files)
                ".venv" # Python virtualenv (common convention)
                "venv" # Python virtualenv (alternate convention)
                ".pytest_cache" # pytest run cache
                ".mypy_cache" # mypy type-checker cache
                ".ruff_cache" # ruff linter cache

                # ── Rust ─────────────────────────────────────────────────────────────────
                "target" # Cargo build artifacts — can be gigabytes; contains binaries

                # ── Go ───────────────────────────────────────────────────────────────────
                # Go outputs to named binaries; no standard ignored dir beyond build/

                # ── Java / JVM ───────────────────────────────────────────────────────────
                ".gradle" # Gradle build cache and wrapper
                ".m2" # Maven local repository cache

                # ── Nix / NixOS ──────────────────────────────────────────────────────────
                "result" # nix build symlink output — points into /nix/store (read-only)
                ".devenv" # devenv state dir — contains symlinks into Nix store + DB files
                ".direnv" # direnv cache — nix-direnv writes shell env here

                # ── Docker / Containers ──────────────────────────────────────────────────
                ".docker" # Docker context and config fragments

                # ── IDEs and editors ─────────────────────────────────────────────────────
                ".idea" # JetBrains IDE project files
                ".vscode" # VS Code workspace settings (unlikely in vault but defensive)

                # ── OS and system ────────────────────────────────────────────────────────
                ".DS_Store" # macOS metadata (irrelevant on NixOS but harmless to list)
                "Thumbs.db" # Windows thumbnail cache

                # ── Logs ─────────────────────────────────────────────────────────────────
                ".log" # Log output directories named .log (tsserver, etc.)
              ];

              # ── Files & attachments ─────────────────────────────────────────────────────

              # Dropped/pasted attachments land in ./assets relative to the current note — keeps repos clean.
              "attachmentFolderPath" = "./assets";

              # New notes are created in the same folder as the currently active note — contextually appropriate.
              "newFileLocation" = "current";

              # ── Safety ──────────────────────────────────────────────────────────────────

              # Confirms before deleting — essential guard when editing files that are symlinked into live repos.
              "promptDelete" = true;

              # Sends deleted files to the system trash — recoverable and keeps the vault directory clean.
              "trashOption" = "system";
            };

            # ── Core Plugins ────────────────────────────────────────────────────────
            # These are Obsidian's built-in plugins. All are enabled by default in
            # the HM module — listed explicitly here so you can comment out what
            # you don't use and have an auditable record.
            corePlugins = [
              # ── Navigation & UI ─────────────────────────────────────────────────────────
              "file-explorer" # left-panel file tree
              "global-search" # vault-wide full-text search
              "switcher" # Ctrl+O (quick open palette) quick note switcher
              "command-palette" # Ctrl+P quick command launcher
              "bookmarks" # persisitent notes, headings, searches to sidebar
              "outline" # heading tree of current note (ease of in-note navigation)
              "page-preview" # hover popover preview on internal links
              "backlink" # shows which notes link to the current note
              "outgoing-link" # panel showing links from current note
              "tag-pane" # tag browser (sidebar listing all tags)
              "word-count" # document word count in status bar

              # ── Editing ─────────────────────────────────────────────────────────────────
              "editor-status" # cursor position in status bar
              "templates" # basic templating (use Templater plugin for power use)
              "note-composer" # merge/split/extract note operations.
              "slash-command" # / trigger for commands inline

              # ── Knowledge graph & canvas ────────────────────────────────────────────────
              "graph" # knowledge graph visualisation (local + global)
              "canvas" # infinite spatial canvas.

              # ── Daily workflow ──────────────────────────────────────────────────────────
              "file-recovery" # snapshot-based file recovery — always keep this on.

              # one-note-per-day journaling / scratchpad
              # Each entry in defaultSettings.corePlugins accepts a settings field of type
              # nullOr (attrsOf anything) — core plugin settings are declared inline on the
              # plugin entry itsel.
              {
                name = "daily-notes";
                settings = {
                  "folder" = "THE_CHAMBER_OF_SECRETS/00_MASTER_JOURNAL/DAILY_NOTES";
                  "format" = "YYYY_MM_DD";
                  "template" = ""; # path to a template note if you want one; empty = none for now
                  "autorun" = false; # true = opens today's note automatically on Obsidian launch
                };
              }

              # ── Data & structure ────────────────────────────────────────────────────────
              "bases" # Obsidian's native database/property system (new in 1.8)
              "properties" # (frontmatter properties panel) surfaces YAML frontmatter as visual property panel.
              "webviewer" # built-in browser pane — needed for webpage cards on canvas

              # ──────────────────────────────────────────────────────────────────────────────
              "audio-recorder" # record audio notes from within Obsidian
              "markdown-importer"
              "slides" # presentation mode for notes
              "workspaces"
              "zk-prefixer"

              # "footnotes"
              # "publish"
              # "random-note"
              # "sync"
            ];

            # ── Community Plugins ───────────────────────────────────────────────────
            # Find plugin IDs at: https://obsidian.md/plugins?search=<name>
            # nixpkgs packages: pkgs.obsidianPlugins.<camelCaseName>
            #
            # Style Settings — exposes Catppuccin theme accent/font controls. Install this FIRST; without it the Catppuccin theme options panel
            # Obsidian Git — auto-commit and push vault to a git remote.
            # Dataview — query your vault like a database using frontmatter. Tag notes with project/status/date and query them in dashboards.
            # Templater — advanced templating with dynamic content. Replaces the built-in Templates for anything non-trivial.
            # Various Complements — autocomplete for wikilinks, tags, and words.
            # Advanced Tables — sane table editing in Markdown.
            # Iconize — add icons to files and folders in the file explorer.
            # Recent Files — sidebar panel of recently opened notes.
            # Better Word Count — counts selection, respects code blocks.
            #
            # ── Community plugins ──────────────────────────────────────────────────
            # Each entry is either a bare derivation (pkg only) or a submodule:
            #   { pkg = <drv>; enable = true; settings = { ... }; }
            # `settings` maps directly to the plugin's .obsidian/plugins/<id>/data.json.
            #
            # HOW TO GET THE HASH for a new plugin:
            #   nix-prefetch fetchFromGitHub --owner <owner> --repo <repo> --rev <tag>
            # or temporarily set hash = lib.fakeHash and let the build fail —
            # the error output contains the correct hash.
            communityPlugins = [

              # Style Settings — REQUIRED for Catppuccin flavor/accent selection.
              # Without this, the Catppuccin options panel in Preferences → Appearance
              # is empty and the theme renders with its default palette only.
              {
                pkg = pluginStyleSettings;
                # settings here become data.json for the style-settings plugin.
                # These keys set Catppuccin Mocha with Mauve accent.
                # Inspect your vault's .obsidian/plugins/obsidian-style-settings/data.json
                # after manual configuration to derive the exact key names.
                settings = {
                  "catppuccin@@flavor" = "mocha"; # Catppuccin flavor: latte | frappe | macchiato | mocha
                  "catppuccin@@accent" = "mauve"; # Catppuccin accent color
                };
              }

              # Obsidian Git — auto-commit vault to a git remote.
              {
                pkg = pluginObsidianGit;
                settings = {
                  "autoSaveInterval" = 15; # commit every 15 minutes
                  "autoPushInterval" = 0; # 0 = push on each commit
                  "commitMessage" = "vault: auto-commit {{date}}";
                  "disablePopups" = false;
                  "showStatusBar" = true;
                };
              }

              # Dataview — query vault frontmatter like a database.
              {
                pkg = pluginDataview;
                settings = {
                  "enableDataviewJs" = true;
                  "enableInlineDataviewJs" = false; # enable only if you use DQL inline
                  "warnOnEmptyResult" = false;
                  "defaultDateFormat" = "dd/MM/yyyy";
                  "defaultDateTimeFormat" = "HH:mm - dd/MM/yyyy";
                };
              }

              # Templater — advanced dynamic templating.
              # Supersedes the built-in Templates plugin for anything non-trivial.
              {
                pkg = pluginTemplater;
                settings = {
                  "trigger_on_file_creation" = false;
                  "auto_jump_to_cursor" = true;
                  "templates_folder" = "TEMPLATES"; # adjust to your vault layout
                };
              }

              {
                pkg = pluginD2;
                settings = {
                  "layoutEngine" = config.cypher-os.apps.productivity.d2.layoutEngine;
                  "themeID" = config.cypher-os.apps.productivity.d2.themeId;
                  "pad" = config.cypher-os.apps.productivity.d2.pad;
                  "sketch" = config.cypher-os.apps.productivity.d2.sketch;
                  "containerHeight" = 800; # px cap before the render scrolls; tune to taste
                  "debounce" = 500; # ms after last keystroke before re-render (plugin min: 100)

                  # "path" left unset deliberately: Obsidian on NixOS/Home Manager inherits
                  # $PATH from the session, and home.sessionVariables in
                  # `modules/apps/productivity/d2/hm.nix` already puts `d2` on it — so the plugin's
                  # own PATH probing (it checks common install locations + $PATH) finds it without help.
                  # Only set this if Obsidian is sandboxed/launched with a stripped PATH
                  # (e.g. a .desktop entry that doesn't source our shell env).
                };
              }

              # Recent Files — sidebar panel of recently opened notes.
              pluginRecentFiles # bare derivation — no settings needed
              pluginCalendar # bare derivation — no settings needed
              pluginAdvancedCanvas
              pluginOptimizeCanvasConnections
              pluginCanvasFilter
            ];

            # ── Themes ─────────────────────────────────────────────────────────────
            # Declares themes available in Obsidian's Appearance → Themes list.
            # `cssTheme` above selects which one is active.
            # Letting catppuccin/nix take control over theming as it should
            #
            # themes = [ themeCatppuccin ];

            # ── CSS snippets ───────────────────────────────────────────────────────
            # Inline snippets (text =) or file references (source =). These are placed
            # in .obsidian/snippets/ and can be toggled in Appearance → CSS Snippets.
            cssSnippets = [
              {
                name = "stop-blinking-cursor";
                text = ''
                  /* Disable blinking cursor in editor */
                  .cm-cursorLayer { animation: none !important; }
                '';
              }
              # To add a file-based snippet:
              # { source = ./snippets/my-snippet.css; }
            ];

            # ── Hotkeys ────────────────────────────────────────────────────────────
            # Maps to hotkeys.json. Format: "plugin-id:command-id" = [ { modifiers = []; key = ""; } ];
            # An empty list removes the default binding for that command.
            hotkeys = {
              # Quick navigation
              "command-palette:open" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "P";
                }
              ];
              "app:open-help" = [ ]; # remove default F1 binding
              "switcher:open" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "O";
                }
              ];
              "editor:swap-line-down" = [
                {
                  modifiers = [ "Alt" ];
                  key = "ArrowDown";
                }
              ];
              "editor:swap-line-up" = [
                {
                  modifiers = [ "Alt" ];
                  key = "ArrowUp";
                }
              ];
              "editor:toggle-bold" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "B";
                }
              ];
              "editor:toggle-italics" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "I";
                }
              ];
              # Sidebar toggles
              "app:toggle-left-sidebar" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "[";
                }
              ];
              "app:toggle-right-sidebar" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "]";
                }
              ];

              # Insert table — requires the Advanced Tables plugin you have declared
              "table-editor-obsidian:insert-table" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "T";
                }
              ];

              # Insert code block — no plugin needed, this is a core editor command
              "editor:insert-code-block" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "K";
                }
              ];

              # Tab management
              "workspace:new-tab" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "N";
                }
              ];
              "workspace:close-tab" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "W";
                }
              ];

              # tab navigation.
              "workspace:next-tab" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Alt"
                  ];
                  key = "ArrowRight";
                }
              ];
              "workspace:previous-tab" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Alt"
                  ];
                  key = "ArrowLeft";
                }
              ];
              "workspace:split-vertical" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "\\";
                }
              ];
              "workspace:split-horizontal" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "-";
                }
              ];

              # History navigation (vi-like keybinding).
              "app:go-back" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Alt"
                  ];
                  key = "H";
                }
              ];
              "app:go-forward" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Alt"
                  ];
                  key = "L";
                }
              ];
              "bookmarks:open" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "B";
                }
              ];

              # Graph
              "graph:open" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "G";
                }
              ];
              "graph:open-local" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Alt"
                  ];
                  key = "G";
                }
              ];

              # Daily note
              "daily-notes:goto-today" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "T";
                }
              ];

              # Fold/unfold headings (very useful for navigating structured notes)
              "editor:fold-all" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = ".";
                }
              ];
              "editor:unfold-all" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = ",";
                }
              ];
              "editor:toggle-fold" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = ".";
                }
              ];

              # Toggle reading vs editing mode
              "markdown:toggle-preview" = [
                {
                  modifiers = [ "Ctrl" ];
                  key = "E";
                }
              ];

              # ── Canvas ───────────────────────────────────────────────────────────────────
              "canvas:new-file" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "C";
                }
              ]; # create new canvas
              "canvas:export-as-image" = [
                {
                  modifiers = [
                    "Ctrl"
                    "Shift"
                  ];
                  key = "E";
                }
              ]; # export canvas to PNG/SVG
              # canvas:convert-to-file has no default — assign if you use inline text cards heavily
              # canvas:zoom-to-fit — already defaults to Shift+1 on most systems; override if needed
            };
          };

          # ── Vault Declaration ────────────────────────────────────────────────────
          # `target` is relative to $HOME. The vault directory will be created by HM
          # if it doesn't exist. Your actual notes inside are never touched — only
          # the .obsidian/ subdirectory is managed.
          # notes, .git, .trash, and everything else are never modified.

          vaults = {
            # Vault name (the Nix attribute key) is arbitrary — it's just an identifier
            # within the HM module. The `target` is what actually matters: it's the path
            # relative to $HOME that HM will manage .obsidian/ inside.
            #
            # If you are coming from an already existing vault with hand-crafted .obsidian/ (appearance.json,
            # app.json, core-plugins.json, graph.json, workspace.json), switching to the
            # declarative module will OVERWRITE those files with HM-managed symlinks.
            # Back up .obsidian/ before your first `home-manager switch` with this enabled:
            #
            #   cp -r ~/PATH/TO/YOUR/VAULT/.obsidian \
            #          ~/PATH/TO/YOUR/VAULT/.obsidian.bak
            #
            # Then inspect the backed-up JSONs to port your existing appearance/app settings
            # into the `settings` block here if you want to preserve them declaratively.
            my-obsidian-notes = {
              target = "DATA/FILES/PROJECTS/PRIVATE/OBSIDIAN_NOTES";
              # vault-specific overrides — uncomment and adjust if this vault
              # should diverge from defaultSettings above.
              # settings.appearance.cssTheme = "Minimal";
              # settings.corePlugins = [ ... ];
              # settings.[app, appearance, corePlugins, communityPlugins, cssSnippets, themes, hotkeys, extraFiles]
            };
          };
        };
      };
}
