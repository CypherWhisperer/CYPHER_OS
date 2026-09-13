# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/media/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.media = {
    enable = lib.mkEnableOption "CypherOS Media related Applications suite";

    vlc.enable = lib.mkEnableOption "VLC Multi-media Desktop App";
    clapper.enable = lib.mkEnableOption "Clapper Multi-media Desktop App";
    spotify.enable = lib.mkEnableOption "Spotify Music Desktop App";
  };
}
