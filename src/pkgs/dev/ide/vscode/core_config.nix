# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/core_config.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  catppuccinAccent = config.cypher-os.theme.flavor;
  catppuccinFlavor = config.cypher-os.theme.flavor;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    programs.vscode.profiles.default.userSettings = cfg._sharedSettings;

    # ── Catppuccin Theme ──────────────────────────────────────────────────
    # Configured via the catppuccin/nix HM module (imported in flake.nix).
    # This approach pre-compiles the chosen flavour at derivation time,
    # which is necessary because the extension normally writes its compiled
    # theme JSON to its own directory at activation — impossible in the
    # read-only Nix store.
    #
    # The module automatically adds the patched extension to programs.vscode
    # and sets workbench.colorTheme in userSettings. We therefore must NOT:
    #   - list catppuccin.catppuccin-vsc in programs.vscode extensions
    #   - set workbench.colorTheme in sharedSettings
    #
    # Flavours: latte (light), frappe, macchiato, mocha (darkest)
    # Accents:  blue, flamingo, green, lavender, maroon, mauve, peach,
    #           pink, red, rosewater, sapphire, sky, teal, yellow
    # ──────────────────────────────────────────────────────────────────────
    catppuccin.vscode.profiles.default = {
      enable = true;
      flavor = catppuccinFlavor;
      accent = catppuccinAccent;
    };

    # programs.vscode.extensions = with pkgs.vscode-extensions; [
    #   # ──────────────────────────────────────────────────────────────────────
    #   # THEME.
    #   # ──────────────────────────────────────────────────────────────────────
    #   # Uncomment to install alongside (switch via
    #   # workbench.colorTheme above):
    #   # enkia.tokyo-night
    #   #
    #   # NOTE: Catppuccin is handled separately via the catppuccin/nix.
    #   #       (see above)
    #   #
    #   # ──────────────────────────────────────────────────────────────────────
    #   # catppuccin.catppuccin-vsc
    #   # dracula-theme.theme-dracula
    #   # zhuangtongfa.material-theme   # One Dark Pro
    #   # jdinhlife.gruvbox
    #   # arcticicestudio.nord-visual-studio-code
    #   # ──────────────────────────────────────────────────────────────────────
    # ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      # ── Theme ───────────────────────────────────────────────────────────────
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
      # NOTE: Catppuccin themes are handled separately via the catppuccin/nix
      # flake module (see below).
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

      # ── File Handling ───────────────────────────────────────────────────────
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

      # ── Explorer ────────────────────────────────────────────────────────────
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "explorer.sortOrder" = "type";

      # ── Git ─────────────────────────────────────────────────────────────────
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;

      # ── Breadcrumbs ─────────────────────────────────────────────────────────
      "breadcrumbs.enabled" = true;

      # ── Security ────────────────────────────────────────────────────────────
      "security.workspace.trust.enabled" = false;
      "security.workspace.trust.untrustedFiles" = "newWindow";
      "security.workspace.trust.startupPrompt" = "never";

      # ── Telemetry ───────────────────────────────────────────────────────────
      "telemetry.telemetryLevel" = "off";
      "redhat.telemetry.enabled" = false;

      # ── Extensions ──────────────────────────────────────────────────────────
      "extensions.autoUpdate" = false;
      "extensions.autoCheckUpdates" = false;
    };

    # ──────────────────────────────────────────────────────────────────────────
    # SHARED SETTINGS DEPLOYMENT.
    # ──────────────────────────────────────────────────────────────────────────
    # Deploy the same settings.json to Cursor and Antigravity. Both editors
    # respect the XDG config path pattern. The JSON is generated from
    # sharedSettings (same source as VSCode).
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."Cursor/User/settings.json".text = builtins.toJSON cfg._sharedSettings;
    xdg.configFile."antigravity/User/settings.json".text = builtins.toJSON cfg._sharedSettings;
  };
}
