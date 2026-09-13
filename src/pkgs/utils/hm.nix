# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/utils/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.utils;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # Packages eligible for both Server and Desktop Profile
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.strace.enable) {
      home.packages = with pkgs; [ strace ];
    })

    (lib.mkIf (cfg.enable && cfg.diskUtils.enable) {
      home.packages = with pkgs; [
        ventoy
        #ventoy-full
        #ventoy-full-qt  # GUI supported qt version
        #ventoy-full-gtk # GUI supported gtk version
        exfatprogs # exFAT filesystem userspace utilities
        dosfstools # Utilities for creating and checking FAT and VFAT file systems
        ntfs3g # FUSE-based NTFS driver with full write support
        parted # Create, destroy, resize, check, and copy partitions
        util-linux # Set of system utilities for Linux
        usbutils # Tools for working with USB devices, such as lsusb
        pciutils # Programs 4 inspecting & manipulating PCI devices configuration
      ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.diskUtils.gui.enable && cfg.diskUtils.gui.gparted.enable) {
      home.packages = with pkgs; [ gparted ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.utils.enable = lib.mkDefault true;
      cypher-os.pkgs.utils.diskUtils.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.utils.diskUtils.gui.enable = lib.mkDefault cfg.diskUtils.enable;
      cypher-os.pkgs.utils.diskUtils.gui.gparted.enable = lib.mkDefault cfg.diskUtils.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.diskUtils.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.utils.diskUtils.enable requires cypher-os.pkgs.utils.enable.
          '';
        }

        {
          assertion = cfg.diskUtils.gui.enable -> cfg.diskUtils.enable;
          message = ''
            cypher-os.pkgs.utils.diskUtils.gui.enable requires cypher-os.pkgs.utils.diskUtils.enable.
          '';
        }

        {
          assertion = cfg.diskUtils.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.utils.diskUtils.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        {
          assertion = cfg.diskUtils.gui.gparted.enable -> cfg.diskUtils.gui.enable;
          message = ''
            cypher-os.pkgs.utils.diskUtils.gui.gparted.enable requires cypher-os.pkgs.utils.gui.enable.
          '';
        }
      ];
    }
  ];
}
