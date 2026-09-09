# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/webstorm.nix
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

  config = lib.mkIf (cfg.enable && cfg.webstorm.enable) {
    home.packages = with pkgs; [
      jetbrains.webstorm
    ];
  };
}
