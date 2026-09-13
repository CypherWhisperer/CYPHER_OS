# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/drawio.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.drawio.enable) {
    home.packages = with pkgs; [ drawio ];
  };
}
