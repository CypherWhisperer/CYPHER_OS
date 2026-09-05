# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/networking/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.pkgs.networking = {
    enable = lib.mkEnableOption "CypherOS Metworking related Packages suite.";
    nmap.enable = lib.mkEnableOption "Nmap FOSS utility for network discovery.";
    tcpdump.enable = lib.mkEnableOption "TCPdump network sniffer.";
    gobuster.enable = lib.mkEnableOption "Gobuster Networking tool.";
    gui = {
      enable = lib.mkEnableOption "CypherOS Metworking related GUI (Graphical User Interface) Packages suite.";
      wireshark.enable = lib.mkEnableOption "Wireshark Network Monitoring tool.";
    };
  };
}
