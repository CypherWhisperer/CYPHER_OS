# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/affine_hm.nix
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

  config = lib.mkIf (cfg.enable && cfg.affine.enable) {
    home.packages = with pkgs; [ affine ];
  };
}
