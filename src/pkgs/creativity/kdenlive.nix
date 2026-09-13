# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/kdenlive.nix
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

  config = lib.mkIf (cfg.enable && cfg.kdenlive.enable) {
    home.packages = with pkgs; [ kdePackages.kdenlive ];
  };
}
