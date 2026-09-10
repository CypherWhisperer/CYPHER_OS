# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/inkscape.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.creativity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.inkscape.enable) {
    home.packages = with pkgs; [ inkscape ];
  };
}
