# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/gimp.nix
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

  config = lib.mkIf (cfg.enable && cfg.gimp.enable) {
    home.packages = with pkgs; [ gimp ];
  };
}
