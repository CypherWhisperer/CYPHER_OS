# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/zettlr
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
# ──────────────────────────────────────────────────────────────────────────────
# Single source of truth for the Zettlr Markdown editor setup.
# Handles: package installation, app configuration, and Catppuccin Mocha
# theming via custom CSS. No manual GUI setup required after activation.
#
# ──────────────────────────────────────────────────────────────────────────────
# SCOPE:
# ──────────────────────────────────────────────────────────────────────────────
# This module is intentionally scoped to Zettlr's role in the broader
# tooling ecosystem:
#
# - Obsidian  → personal notes, second brain, PKM (vault-based)
# - VSCode    → development-context Markdown (codebases, docs, ADRs)
# - Zettlr   → vault-free, filesystem-native Markdown; the "open-with" fallback
#              for any .md file that belongs to neither world
#
# ──────────────────────────────────────────────────────────────────────────────
# DEPENDENCIES:
# ──────────────────────────────────────────────────────────────────────────────
# - pkgs.zettlr  — the app itself
# - pkgs.pandoc  — required for Zettlr's export pipeline (PDF, DOCX, etc.)
#                  Without pandoc, the Export menu is largely non-functional.
#                  Declared here since it is a functional dependency of this
#                  module, not a general-purpose tool.
#
# ──────────────────────────────────────────────────────────────────────────────
# THEMING STRATEGY:
# ──────────────────────────────────────────────────────────────────────────────
# Zettlr ships five built-in themes (Berlin, Frankfurt, Bielefeld,
# Karl-Marx-Stadt, Bordeaux). None are Catppuccin. There is no official
# Catppuccin port in the catppuccin org for Zettlr as of 2026.
#
# Solution: Custom CSS injected via `~/.config/Zettlr/custom.css`.  Zettlr loads
# this file on top of the selected base theme. We use "berlin" as the base
# (default, neutral green accent, sans-serif) and fully override its color
# surface with Catppuccin Mocha tokens.
#
# Flavor: Mocha (dark) — consistent with the rest of the CypherOS setup
# (VSCode, Obsidian, Neovim, terminal). The Latte (light) palette is included as
# a commented reference block for future opt-in.
#
# ──────────────────────────────────────────────────────────────────────────────
# CONFIG FILE LOCATION:
# ──────────────────────────────────────────────────────────────────────────────
# Zettlr reads:
# ${cypherOsConstants.homeDirectory}/.config/Zettlr/config.json (app settings)
# ${cypherOsConstants.homeDirectory}/.config/Zettlr/custom.css  (theme override)
#
# Both are managed declaratively here via xdg.configFile.
# Do NOT edit these files manually — changes will be overwritten on
#   `home-manager switch`. Make all changes in this module instead.
#
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.editor.gui;

  # ────────────────────────────────────────────────────────────────────────────
  # Catppuccin Mocha palette — defined as a Nix attribute set so values can be
  # referenced in both the CSS string and any future Nix-level logic without
  # duplicating hex codes. This is the canonical palette for this module.
  #
  # Source: https://github.com/catppuccin/catppuccin
  # ────────────────────────────────────────────────────────────────────────────
  mocha = {
    # Backgrounds (darkest → lightest)
    crust = "#11111b";
    mantle = "#181825";
    base = "#1e1e2e";
    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";
    # Text / overlays
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    text = "#cdd6f4";
    # Accent colors — mapped to Markdown element roles below
    lavender = "#b4befe"; # → active/selected items, cursor
    blue = "#89b4fa"; # → links, H2
    sapphire = "#74c7ec"; # → URLs, H3
    sky = "#89dceb"; # → H4–H6
    teal = "#94e2d5"; # → (reserved / future use)
    green = "#a6e3a1"; # → inline code, code blocks
    yellow = "#f9e2af"; # → italic/emphasis
    peach = "#fab387"; # → bold/strong
    maroon = "#eba0ac"; # → (reserved / future use)
    red = "#f38ba8"; # → errors / spellcheck underline target
    mauve = "#cba6f7"; # → H1, tags (#tag), primary accent
    pink = "#f5c2e7"; # → (reserved / future use)
    flamingo = "#f2cdcd"; # → (reserved / future use)
    rosewater = "#f5e0dc"; # → (reserved / future use)
  };

  zettlrConfig = builtins.toJSON {
    # ──────────────────────────────────────────────────────────────────────────
    # APPEARANCE.
    # ──────────────────────────────────────────────────────────────────────────
    # darkTheme: enables dark mode globally. Pairs with the Mocha CSS theme.
    # ──────────────────────────────────────────────────────────────────────────
    darkTheme = true;

    # ──────────────────────────────────────────────────────────────────────────
    # theme: the base built-in theme. "berlin" is the default (green accent,
    # sans-serif). The custom CSS fully overrides its color surface, so the
    # accent color of the base theme is irrelevant — berlin is chosen for its
    # clean geometry and sans-serif typography baseline.
    # ──────────────────────────────────────────────────────────────────────────
    theme = "berlin";

    # ──────────────────────────────────────────────────────────────────────────
    # muteLines: grays out all lines except the one under the cursor (iA Writer
    # style). Disabled — it is useful for long-form prose but creates visual
    # noise when scanning technical documentation or reviewing structure.
    # ──────────────────────────────────────────────────────────────────────────
    muteLines = false;

    # ──────────────────────────────────────────────────────────────────────────
    # FILE HANDLING.
    # ──────────────────────────────────────────────────────────────────────────
    # alwaysReloadFiles: silently reload a file if it has been modified
    # externally. Critical for this workflow — the same .md file may be edited
    # in VSCode or via the terminal, and Zettlr should pick up changes without
    # prompting. Avoids the "file changed on disk" dialog friction.
    # ──────────────────────────────────────────────────────────────────────────
    alwaysReloadFiles = true;

    # ──────────────────────────────────────────────────────────────────────────
    # avoidNewTabs: replace the current editor tab rather than opening a new one
    # for each file. Zettlr is used as an "open with" app, not a
    # multi-document workspace — tab accumulation is unwanted.
    # ──────────────────────────────────────────────────────────────────────────
    avoidNewTabs = true;

    # ──────────────────────────────────────────────────────────────────────────
    # EDITOR.
    # ──────────────────────────────────────────────────────────────────────────
    editor = {
      # ────────────────────────────────────────────────────────────────────────
      # inputMode: "default" | "vim" | "emacs"
      # Using default here intentionally. Zettlr is the fallback viewer/editor,
      # not the daily driver for development writing. Modal editing investment
      # lives in Neovim (CypherIDE). Switching to "vim" is a one-line change
      # when/if desired.
      # ────────────────────────────────────────────────────────────────────────
      inputMode = "default";

      indentUnit = 2;
      indentWithTabs = false;

      # ────────────────────────────────────────────────────────────────────────
      # autoCloseBrackets: auto-inserts closing ), ], } as you type.
      # Useful even in Markdown for link syntax [text](url).
      # ────────────────────────────────────────────────────────────────────────
      autoCloseBrackets = true;

      # ────────────────────────────────────────────────────────────────────────
      # autoCorrect: disabled for technical/development writing.
      # Autocorrect is built for prose and interferes with code blocks,
      # CLI snippets, paths, and Markdown syntax. Magic quotes similarly
      # break backtick strings and code. Both are off.
      # ────────────────────────────────────────────────────────────────────────
      #autoCorrect = {
      #  active = false;
      #  magicQuotes = false;
      #};

      # ────────────────────────────────────────────────────────────────────────
      # NOTE: after encountering error (Could not start ConfigFile: Cannot use
      # 'in' operator to search for 'primary' in false):
      #
      # autoCorrect is intentionally omitted — Zettlr's internal schema for this
      # field includes keys (e.g. "primary") we don't know the shape of.
      #
      # Omitting it lets Zettlr seed its own correct defaults. If autocorrect
      # configuration is needed, do it via the GUI and observe what Zettlr
      # writes to config.json, then mirror that shape here.
      # ────────────────────────────────────────────────────────────────────────
    };

    # ───────────────────────────────────────────────────────────────────────────
    # DISPLAY.
    # ───────────────────────────────────────────────────────────────────────────
    display = {
      renderImages = true;
      renderLinks = true;

      # ────────────────────────────────────────────────────────────────────────
      # renderMath: disabled. LaTeX math is not part of this workflow.
      # enable if writing documents with equations.
      # ────────────────────────────────────────────────────────────────────────
      renderMath = false;

      # ────────────────────────────────────────────────────────────────────────
      # renderTasks: renders [ ] and [x] as visual checkboxes.
      # Useful for task lists in project notes and READMEs.
      # ────────────────────────────────────────────────────────────────────────
      renderTasks = true;

      renderHeadingNumbers = false;
    };

    # ──────────────────────────────────────────────────────────────────────────
    # SPELL CHECK.
    # ──────────────────────────────────────────────────────────────────────────
    # Hunspell-compatible dictionaries. Add more locales as needed.
    # Dictionary packages (e.g. hunspellDicts.en_GB) must be in home.packages
    # or environment.systemPackages if Zettlr cannot find them automatically.
    # ──────────────────────────────────────────────────────────────────────────
    selectedDicts = [ "en-GB" ];
  };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.zettlr.enable) {

    # ──────────────────────────────────────────────────────────────────────────
    # PACKAGES
    # ──────────────────────────────────────────────────────────────────────────
    home.packages = with pkgs; [
      zettlr

      # ────────────────────────────────────────────────────────────────────────
      # Pandoc: Zettlr's export engine. Required for File → Export to work.
      # Produces PDF (via LaTeX), DOCX, HTML, & other formats from Markdown.
      # Declared here rather than in a global packages list to keep the
      # dependency collocated with the tool that needs it.
      # ────────────────────────────────────────────────────────────────────────
      pandoc
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # CUSTOM CSS —:
    #  ${cypherOsConstants.homeDirectory}/.config/Zettlr/custom.css
    # ──────────────────────────────────────────────────────────────────────────
    # Catppuccin Mocha theme for Zettlr.
    # ──────────────────────────────────────────────────────────────────────────
    # Architecture:
    #   - CSS custom properties (vars) are declared on `body.dark` so they
    #     are scoped to dark mode only and do not bleed into light mode.
    #
    #   - All overrides are prefixed with `body.dark` for the same reason.
    #
    #   - Zettlr's own rules use `!important` sparingly, but some surfaces
    #     require it to win specificity battles with the base theme.
    #
    #   - Geometry (margins, padding, sizes) is intentionally NOT touched.
    #     Zettlr's layout depends on correct element sizing; color-only
    #     overrides are safe.
    #
    # ──────────────────────────────────────────────────────────────────────────
    # Markdown → Color mapping rationale:
    #   H1        → mauve   (primary heading, most prominent accent)
    #   H2        → blue    (secondary, cool and readable)
    #   H3        → sapphire
    #   H4–H6     → sky     (tertiary, de-emphasized)
    #   Bold      → peach   (warm, stands out from body text)
    #   Italic    → yellow  (warm but softer than bold)
    #   Links     → blue    (conventional; matches H2 intentionally)
    #   URLs      → sapphire
    #   Code      → green   (conventional terminal/code color)
    #   Blockquote→ overlay2 (muted; not primary content)
    #   Tags (#)  → mauve + surface0 bg (pill-style, matches H1 accent)
    #   Cursor    → lavender (distinctive, not harsh)
    #   Selection → surface1 (subtle, non-distracting)
    # ──────────────────────────────────────────────────────────────────────────

    xdg.configFile."Zettlr/custom.css".text = ''
      /* ─────────────────────────────────────────────────────────────────────────────
         Catppuccin Mocha — Zettlr Custom CSS
         Flavor  : Mocha (dark)
         Managed : declaratively via Home Manager (zettlr.nix)
         DO NOT EDIT THIS FILE MANUALLY — changes will be overwritten on switch.
         Source of truth: modules/zettlr.nix in your Home Manager config.
         ───────────────────────────────────────────────────────────────────────────── */

      /* ─────────────────────────────────────────────────────────────────────────────
         PALETTE — CSS custom properties scoped to dark mode.
         Mirrors the `mocha` Nix attrset in zettlr.nix for runtime CSS access.
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark {
        --ctp-crust:     ${mocha.crust};
        --ctp-mantle:    ${mocha.mantle};
        --ctp-base:      ${mocha.base};
        --ctp-surface0:  ${mocha.surface0};
        --ctp-surface1:  ${mocha.surface1};
        --ctp-surface2:  ${mocha.surface2};
        --ctp-overlay0:  ${mocha.overlay0};
        --ctp-overlay1:  ${mocha.overlay1};
        --ctp-overlay2:  ${mocha.overlay2};
        --ctp-subtext0:  ${mocha.subtext0};
        --ctp-subtext1:  ${mocha.subtext1};
        --ctp-text:      ${mocha.text};
        --ctp-lavender:  ${mocha.lavender};
        --ctp-blue:      ${mocha.blue};
        --ctp-sapphire:  ${mocha.sapphire};
        --ctp-sky:       ${mocha.sky};
        --ctp-teal:      ${mocha.teal};
        --ctp-green:     ${mocha.green};
        --ctp-yellow:    ${mocha.yellow};
        --ctp-peach:     ${mocha.peach};
        --ctp-maroon:    ${mocha.maroon};
        --ctp-red:       ${mocha.red};
        --ctp-mauve:     ${mocha.mauve};
        --ctp-pink:      ${mocha.pink};
        --ctp-flamingo:  ${mocha.flamingo};
        --ctp-rosewater: ${mocha.rosewater};
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         APP SHELL — main background and body text
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark #app-container {
        background-color: var(--ctp-base)  !important;
        color:            var(--ctp-text)  !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         TOOLBAR
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark #toolbar {
        background-color: var(--ctp-mantle)   !important;
        border-bottom:    1px solid var(--ctp-surface0) !important;
      }

      body.dark #toolbar button {
        color: var(--ctp-subtext1) !important;
      }

      body.dark #toolbar button:hover {
        background-color: var(--ctp-surface0) !important;
        color:            var(--ctp-text)     !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         SIDEBAR / FILE MANAGER
         The sidebar is the primary navigation surface — keep it clearly distinct
         from the editor (mantle vs base) while sharing the same color language.
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark #file-manager {
        background-color: var(--ctp-mantle)   !important;
        border-right:     1px solid var(--ctp-surface0) !important;
      }

      body.dark .file-list-item,
      body.dark .dir-tree-item {
        color: var(--ctp-subtext1) !important;
      }

      body.dark .file-list-item:hover,
      body.dark .dir-tree-item:hover {
        background-color: var(--ctp-surface0) !important;
        color:            var(--ctp-text)     !important;
      }

      /* Active (currently open) file — lavender accent, consistent with cursor */
      body.dark .file-list-item.active,
      body.dark .dir-tree-item.active {
        background-color: var(--ctp-surface1)  !important;
        color:            var(--ctp-lavender)  !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         EDITOR SURFACE — CodeMirror canvas
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark #editor {
        background-color: var(--ctp-base) !important;
      }

      body.dark .CodeMirror {
        background-color: var(--ctp-base) !important;
        color:            var(--ctp-text) !important;
      }

      /* Cursor — lavender is distinctive without being harsh */
      body.dark .CodeMirror-cursor {
        border-left-color: var(--ctp-lavender) !important;
      }

      /* Selection highlight */
      body.dark .CodeMirror-selected,
      body.dark .CodeMirror-focused .CodeMirror-selected {
        background-color: var(--ctp-surface1) !important;
      }

      /* Gutter (line numbers area) */
      body.dark .CodeMirror-gutters {
        background-color: var(--ctp-mantle)   !important;
        border-right:     1px solid var(--ctp-surface0) !important;
      }

      body.dark .CodeMirror-linenumber {
        color: var(--ctp-overlay0) !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         HEADINGS
         Descending prominence: mauve → blue → sapphire → sky (H4–H6)
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-header-1 { color: var(--ctp-mauve)   !important; font-weight: bold; }
      body.dark .cm-header-2 { color: var(--ctp-blue)    !important; }
      body.dark .cm-header-3 { color: var(--ctp-sapphire)!important; }
      body.dark .cm-header-4,
      body.dark .cm-header-5,
      body.dark .cm-header-6 { color: var(--ctp-sky)     !important; }

      /* ─────────────────────────────────────────────────────────────────────────────
         INLINE FORMATTING
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-strong {
        color:       var(--ctp-peach) !important;
        font-weight: bold;
      }

      body.dark .cm-em {
        color:       var(--ctp-yellow) !important;
        font-style:  italic;
      }

      /* Links: blue (matches H2 — intentional visual grouping of "navigable" elements) */
      body.dark .cm-link {
        color: var(--ctp-blue) !important;
      }

      body.dark .cm-url {
        color: var(--ctp-sapphire) !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         CODE — inline and fenced blocks
         Green is the conventional code/terminal color in Catppuccin.
         Mantle background gives inline code a subtle pill appearance.
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-comment,
      body.dark .cm-monospace {
        color:            var(--ctp-green)  !important;
        background-color: var(--ctp-mantle) !important;
        border-radius:    3px;
        padding:          0 2px;
      }

      /* Fenced code block background */
      body.dark .CodeMirror-line .cm-code-block {
        background-color: var(--ctp-mantle) !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         BLOCKQUOTES
         De-emphasized with overlay2 text and a surface2 left border.
         Blockquotes are secondary content; they should recede visually.
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-quote {
        color:       var(--ctp-overlay2) !important;
        border-left: 3px solid var(--ctp-surface2);
        padding-left: 8px;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         TAGS — Zettlr's #hashtag system
         Pill style: mauve text on surface0 background.
         Mauve is the primary accent (shared with H1) — tags are first-class
         citizens in Zettlr's organization model.
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-zkn-tag,
      body.dark .zkn-tag {
        color:            var(--ctp-mauve)   !important;
        background-color: var(--ctp-surface0)!important;
        border-radius:    4px;
        padding:          1px 5px;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         INTERNAL LINKS — [[wiki-style]] links (Zettelkasten)
         Sapphire distinguishes them from external [markdown](links) (blue).
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-zkn-link {
        color: var(--ctp-sapphire) !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         HORIZONTAL RULE
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .cm-hr {
        color: var(--ctp-surface2) !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         SEARCH / HIGHLIGHT
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark .CodeMirror-matchingbracket {
        color:            var(--ctp-green)   !important;
        background-color: var(--ctp-surface1)!important;
      }

      body.dark .cm-searching {
        background-color: var(--ctp-yellow) !important;
        color:            var(--ctp-base)   !important;
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         SCROLLBARS — thin, Mocha-tinted, consistent with terminal/editor style
         ───────────────────────────────────────────────────────────────────────────── */
      body.dark ::-webkit-scrollbar {
        width:  6px;
        height: 6px;
      }

      body.dark ::-webkit-scrollbar-track {
        background: var(--ctp-mantle);
      }

      body.dark ::-webkit-scrollbar-thumb {
        background:    var(--ctp-surface1);
        border-radius: 3px;
      }

      body.dark ::-webkit-scrollbar-thumb:hover {
        background: var(--ctp-surface2);
      }

      /* ─────────────────────────────────────────────────────────────────────────────
         CATPPUCCIN LATTE — Light mode palette (reference / opt-in)
         To activate: change `darkTheme = false` in config.json and switch the
         selectors below from `body:not(.dark)` to whatever Zettlr uses for light.
         Uncomment when needed.
         ─────────────────────────────────────────────────────────────────────────────

      body:not(.dark) {
        --ctp-base:      #eff1f5;
        --ctp-mantle:    #e6e9ef;
        --ctp-crust:     #dce0e8;
        --ctp-surface0:  #ccd0da;
        --ctp-surface1:  #bcc0cc;
        --ctp-surface2:  #acb0be;
        --ctp-overlay0:  #9ca0b0;
        --ctp-overlay1:  #8c8fa1;
        --ctp-overlay2:  #7c7f93;
        --ctp-subtext0:  #6c6f85;
        --ctp-subtext1:  #5c5f77;
        --ctp-text:      #4c4f69;
        --ctp-lavender:  #7287fd;
        --ctp-blue:      #1e66f5;
        --ctp-sapphire:  #209fb5;
        --ctp-sky:       #04a5e5;
        --ctp-green:     #40a02b;
        --ctp-yellow:    #df8e1d;
        --ctp-peach:     #fe640b;
        --ctp-red:       #d20f39;
        --ctp-mauve:     #8839ef;
        --ctp-pink:      #ea76cb;
      }

      ───────────────────────────────────────────────────────────────────────────── */
    '';

    # ──────────────────────────────────────────────────────────────────────────
    # APP CONFIGURATION —:
    #  ${cypherOsConstants.homeDirectory}/.config/Zettlr/config.json
    # ──────────────────────────────────────────────────────────────────────────
    # Zettlr stores all settings in a single JSON file. We generate it with
    # builtins.toJSON to keep it typed and diffable.
    #
    # NOTE: Zettlr may write additional runtime keys to this file (e.g.,
    # window geometry, last open files).
    #
    # Those are ephemeral and do not conflict with declarative keys — Zettlr
    # merges config on load. The keys set here represent intentional,
    # stable preferences.
    # ──────────────────────────────────────────────────────────────────────────
    home.activation.zettlrConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Write Zettlr config.json only if it does not already exist.
      # This seeds the initial config from Nix without making the file
      # read-only — Zettlr can mutate it freely at runtime.
      #
      # To reset to these defaults: rm ~/.config/Zettlr/config.json
      # then run home-manager switch.
      ZETTLR_CONFIG="$HOME/.config/Zettlr/config.json"
      if [ ! -f "$ZETTLR_CONFIG" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$ZETTLR_CONFIG")"
        $DRY_RUN_CMD cp ${pkgs.writeText "zettlr-config.json" zettlrConfig} "$ZETTLR_CONFIG"
        $DRY_RUN_CMD chmod 644 "$ZETTLR_CONFIG"
      fi
    '';
  };
}
