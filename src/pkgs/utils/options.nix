# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/utils/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.pkgs.utils = {
    enable = lib.mkEnableOption "CypherOS Utilities Packages Suite.";
    strace = lib.mkEnableOption "Strace System Call tracer for Linux.";
    diskUtils = {
      enable = lib.mkEnableOption "CypherOS Disk Packages Utilities.";
      gui = {
        enable = lib.mkEnableOption "Disk Utilities GUI (Graphical User Interface) Packages Suite";
        gparted = lib.mkEnableOption "GParted Graphical disk partitioning tool.";
      }
    };

  }
}
