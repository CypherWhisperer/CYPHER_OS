# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/staruml.nix
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

  config = lib.mkIf (cfg.enable && cfg.staruml.enable) {
    home.packages = with pkgs; [ staruml ];
  };
}
