# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/media/spotify.nix
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

  config = lib.mkIf (cfg.enable && cfg.spotify.enable) {
    home.packages = with pkgs; [ spotify ];
  };
}
