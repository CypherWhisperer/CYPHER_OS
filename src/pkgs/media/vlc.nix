# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/media/vlc.nix
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

  config = lib.mkIf (cfg.enable && cfg.vlc.enable) {
    home.packages = with pkgs; [ vlc ];
  };
}
