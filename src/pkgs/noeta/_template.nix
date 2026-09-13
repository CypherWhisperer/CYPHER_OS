# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/L.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.L.enable) {
    home.packages = with pkgs; [ ];
  };
}
