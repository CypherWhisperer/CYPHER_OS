# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/cursor.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.cursor.enable) {
    home.packages = with pkgs; [
      code-cursor
    ];
  };
}
