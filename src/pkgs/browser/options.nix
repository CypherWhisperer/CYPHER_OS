# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.browser = {
    enable = lib.mkEnableOption "Browser applications (namespace kill-switch)";

    brave.enable = lib.mkEnableOption "Brave web browser";
    firefox.enable = lib.mkEnableOption "Firefox web browser (hardened + Arkenfox)";
    librewolf.enable = lib.mkEnableOption "LibreWolf — privacy-first Firefox fork";
    mullvad.enable = lib.mkEnableOption "Mullvad Browser — fingerprint-uniform clearnet browser";
    tor.enable = lib.mkEnableOption "Tor Browser — anonymity-grade browser";
  };
}
