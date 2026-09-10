# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/communication/telegram.nix
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

  config = lib.mkIf (cfg.enable && cfg.telegram.enable) {
    home.packages = with pkgs; [ telegram-desktop ];
  };
}
