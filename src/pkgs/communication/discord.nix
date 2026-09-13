# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/communication/discord.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.communication;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.discord.enable) {
    home.packages = with pkgs; [ discord ];
  };
}
