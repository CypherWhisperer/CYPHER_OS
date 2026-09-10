# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/communication/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.communication = {
    enable = lib.mkEnableOption "CypherOS Communication Applications";

    signal.enable = lib.mkEnableOption "Signal Desktop App";
    karere.enable = lib.mkEnableOption "Karere Desktop App";
    discord.enable = lib.mkEnableOption "Discord Desktop App";
    telegram.enable = lib.mkEnableOption "Telegram Desktop App";
  };
}
