# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/d2.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.d2.enable) {
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

        # ────── D2 Diagramming ──────────────────────────────────────────
        vscMkt.terrastruct.d2
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # D2
      # ────────────────────────────────────────────────────────────────────────
      "d2.layout" = config.cypher-os.pkgs.dev.languages.d2.layoutEngine;
      "d2.theme" = config.cypher-os.pkgs.dev.languages.d2.themeId;
      "d2.darkTheme" = config.cypher-os.pkgs.dev.languages.d2.darkThemeId;
      "d2.pad" = config.cypher-os.pkgs.dev.languages.d2.pad;
      # ────────────────────────────────────────────────────────────────────────
      # "D2.checkForInstallAtStart" defaults to true and just verifies the CLI
      # is reachable on activation — harmless to leave at default.
      # ────────────────────────────────────────────────────────────────────────
    };
  };
}
