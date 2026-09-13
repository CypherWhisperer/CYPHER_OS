# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/audacity.nix
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

  config = lib.mkIf (cfg.enable && cfg.audacity.enable) {
    home.packages = with pkgs; [ audacity ];
  };
}
