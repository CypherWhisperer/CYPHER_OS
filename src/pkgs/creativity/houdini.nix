# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/houdini.nix
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

  config = lib.mkIf (cfg.enable && cfg.houdini.enable) {
    home.packages = with pkgs; [ houdini ];
  };
}
