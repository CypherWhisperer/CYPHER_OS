# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/antigravity.nix
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

  config = lib.mkIf (cfg.enable && cfg.antigravity.enable) {
    home.packages = with pkgs; [
      antigravity
      #antigravity-fhs
    ];
  };
}
