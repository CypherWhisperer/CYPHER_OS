# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/krita.nix
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

  config = lib.mkIf (cfg.enable && cfg.krita.enable) {
    home.packages = with pkgs; [ krita ];
  };
}
