# ──────────────────────────────────────────────────────────────────────────────
# src/privacy/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.privacy = {
    enable = lib.mkEnableOption "CypherOS Privacy Packages suite.";
    tor = lib.mkEnableOption "Tor Anonymizing Overlay Network.";
    gui = {
      enable = lib.mkEnableOption "CypherOS Privacy related GUI (Graphical User Interface) Packages suite.";
      megasync = lib.mkEnableOption "Mega Sync Privacy-oriented Cloud Storage Provider.";
      protonSuite = {
        enable = lib.mkEnableOption "Proton Ecosystem Application Suite";
      };
    };
  }
}
