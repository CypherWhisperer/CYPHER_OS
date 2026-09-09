# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/sql.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.sql.enable) {
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
        vscMkt.mtxr.sqltools
        vscMkt.mtxr.sqltools-driver-pg
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # SQLTools connections are added interactively via the SQLTools panel
      # (they contain credentials — not declared here).
      # Driver format hint: PostgreSQL connection stored in
      # $XDG_CONFIG_HOME/Code/User/settings.json under "sqltools.connections"
      # once you add one via the UI.
      # ────────────────────────────────────────────────────────────────────────
      "sqltools.useNodeRuntime" = true;
      "sqltools.autoOpenSessionFiles" = false;
    };
  };
}
