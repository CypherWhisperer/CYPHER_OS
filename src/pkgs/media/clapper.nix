# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/media/clapper.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.media;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.clapper.enable) {
    home.packages = with pkgs; [ clapper ];
  };
}
