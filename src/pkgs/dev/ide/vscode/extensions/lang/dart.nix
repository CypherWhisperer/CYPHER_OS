# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/dart.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  #vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.dart.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # Flutter tooling, hot reload, device management
        # ──────────────────────────────────────────────────────────────────────
        dart-code.flutter

        # ──────────────────────────────────────────────────────────────────────
        # Dart language support flutter (depends on this)
        # ──────────────────────────────────────────────────────────────────────
        dart-code.dart-code
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # Flutter SDK path: Home Manager installs flutter to the Nix store.
      # The path below is set dynamically — replace with the actual store path
      # or set it to the flutter binary location after first switch:
      #   `which flutter | xargs dirname | xargs dirname`
      #  e.g /etc/profiles/per-user/cypher_whisperer
      # Alternatively leave unset and let the extension auto-detect.
      # "dart.flutterSdkPath" = "/path/to/flutter";  # set after first switch
      # ────────────────────────────────────────────────────────────────────────
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
    };
  };
}
