# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/networking/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.pkgs.networking = {
    enable = lib.mkEnableOption "CypherOS Metworking related Packages suite.";
    nmap = lib.mkEnableOption "Nmap FOSS utility for network discovery.";
    tcpdump = lib.mkEnableOption "TCPdump network sniffer.";
    gobuster = lib.mkEnableOption "Gobuster Networking tool.";
    gui = {
      enable = lib.mkEnableOption "CypherOS Metworking related GUI (Graphical User Interface) Packages suite.";
      wireshark = lib.mkEnableOption "Wireshark Network Monitoring tool.";
    };
  }
}
