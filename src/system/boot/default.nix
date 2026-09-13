# ──────────────────────────────────────────────────────────────────────────────
# src/system/boot/default.nix
# ──────────────────────────────────────────────────────────────────────────────
# Owns everything boot-related for the cypher-nixos host:
#
#   1. Bootloader (GRUB EFI) — configuration, hardening, theming scaffold
#
#   2. EFI partition mount — pulled in here for reproducibility (not left
#      solely to hardware-configuration.nix which is auto-generated and
#      can be overwritten by nixos-generate-config)
#
#   3. Boot partition health check — systemd oneshot that surfaces a
#      read-only or space-critical /boot BEFORE a rebuild hits it
#
#   4. cypher-rebuild script — canonical rebuild command with
#      --install-bootloader always included; prevents the class of incident
#      documented in INC-24-04-2026
#
# NOTE ON hardware-configuration.nix:
#   The fileSystems."/boot" entry generated there uses fmask/dmask=0022
#   (world-readable). This module overrides it to 0077 (owner-only).
#   NixOS merges fileSystems entries by mount point — the mkForce here
#   wins cleanly. You can remove the /boot entry from hardware-configuration.nix
#   entirely once confirmed this works, to avoid the duplication.
# ──────────────────────────────────────────────────────────────────────────────
# efi.canTouchEfiVariables = true: lets NixOS write its boot entry to NVRAM.
# Required for systemd-boot to work on most UEFI firmware.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    # ──────────────────────────────────────────────────────────────────────────
    # 1. BOOTLOADER
    # ──────────────────────────────────────────────────────────────────────────
    loader = {
      # ────────────────────────────────────────────────────────────────────────
      # systemd-boot is the leading candidate for CypherOS (see OQ6 in
      # architecture). It handles a shared ESP cleanly — each OS gets its own
      # loader entry in /boot/EFI/<os-name>/ and systemd-boot presents them all at
      # startup.
      #
      # Though GRUB is currently active for now. Explicitly disabled to avoid
      # accidental co-activation.
      # ────────────────────────────────────────────────────────────────────────
      systemd-boot.enable = false;

      grub = {
        enable = true;

        # ──────────────────────────────────────────────────────────────────────
        # EFI mode — "nodev" means GRUB is installed to the ESP, not to
        # an MBR. Required when efiSupport = true.
        # ──────────────────────────────────────────────────────────────────────
        device = "nodev";
        efiSupport = true;

        # ──────────────────────────────────────────────────────────────────────
        # Identify partitions by filesystem UUID rather than device path
        # (e.g. /dev/sda2). Device paths can shift when drives are added,
        # removed, or reordered. UUIDs are stable across reboots.
        # ──────────────────────────────────────────────────────────────────────
        fsIdentifier = "uuid";

        # ──────────────────────────────────────────────────────────────────────
        # Copy kernel and initrd files directly into /boot/kernels/ at
        # build time, rather than having GRUB resolve symlinks into
        # /nix/store at boot time. Benefits:
        #   - GRUB can find kernels even if the Nix store subvolume has
        #     a mount issue
        #   - Simpler, flatter path resolution — no cross-subvolume traversal
        #   - More robust on BTRFS where GRUB's subvol addressing is fragile
        # ──────────────────────────────────────────────────────────────────────
        copyKernels = true;

        # ──────────────────────────────────────────────────────────────────────
        # Do not probe for other installed OSes automatically. For CypherOS,
        # other boot entries will be managed explicitly — either through
        # additional NixOS GRUB menu entries or by switching to systemd-boot
        # which natively handles multi-loader ESPs.
        # Set to true temporarily if you need to discover a non-NixOS OS.
        # ──────────────────────────────────────────────────────────────────────
        useOSProber = false;

        # ──────────────────────────────────────────────────────────────────────
        # Bootloader Generation Retention
        # ──────────────────────────────────────────────────────────────────────
        # Maximum number of NixOS generations shown in the GRUB menu. Each
        # generation entry also occupies space in /boot
        # (when copyKernels = true). 10 is a safe balance between having
        # meaningful rollback depth and keeping /boot from filling up. The
        # FAT32 EFI partition is typically 256–512 MB — treat it as a finite
        # resource.
        # ──────────────────────────────────────────────────────────────────────
        configurationLimit = 10;

        # ──────────────────────────────────────────────────────────────────────
        # GRUB THEMING
        # ──────────────────────────────────────────────────────────────────────
        # NixOS can point GRUB at a theme directory in the Nix store.
        # This is equivalent to setting GRUB_THEME in /etc/default/grub.
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # HOW TO USE A LOCAL THEME DIRECTORY:
        # ──────────────────────────────────────────────────────────────────────
        #theme = pkgs.stdenv.mkDerivation {
        #  name = "grub-theme-cypher";
        #  src = path/to/theme-directory;
        #  installPhase = ''
        #    mkdir -p $out
        #    cp -r . $out
        #  '';
        #};

        # ──────────────────────────────────────────────────────────────────────
        # HOW TO USE A PACKAGED THEME (if available in nixpkgs):
        # ──────────────────────────────────────────────────────────────────────
        # Other options: pkgs.grub2-themes.{tela,whitesur,vimix}
        # ──────────────────────────────────────────────────────────────────────
        theme = pkgs.catppuccin-grub;

        # ──────────────────────────────────────────────────────────────────────
        # HOW TO USE A SPLASH IMAGE ONLY (simpler, no full theme):
        # ──────────────────────────────────────────────────────────────────────
        # Must be 640x480 or 1024x768 PNG. Set to null to disable.
        #
        # The theme directory must contain a theme.txt file — same
        # structure as a Ventoy theme drop-in. If your existing theme
        # directories work with Ventoy/standalone GRUB, they will work
        # here with no modification.
        # ──────────────────────────────────────────────────────────────────────
        #splashImage = path/to/grub/background.png;
      };

      efi = {
        # ──────────────────────────────────────────────────────────────────────
        # Allow NixOS to write its boot entry to UEFI NVRAM. Required for
        # GRUB EFI to register itself with the firmware so it appears in
        # the firmware boot menu.
        # ──────────────────────────────────────────────────────────────────────
        canTouchEfiVariables = true;

        # ──────────────────────────────────────────────────────────────────────
        # Mount point of the EFI System Partition. Must match the
        # fileSystems entry below.
        # ──────────────────────────────────────────────────────────────────────
        efiSysMountPoint = "/boot";
      };

      # ────────────────────────────────────────────────────────────────────────
      # Seconds to wait at the GRUB menu before auto-booting the default
      # entry. 0 = instant (no menu visible on clean boot, but accessible
      # by holding Shift). 5 is a reasonable default.
      # ────────────────────────────────────────────────────────────────────────
      timeout = 5;
    };

    # ──────────────────────────────────────────────────────────────────────────
    # KERNEL EXTRA MODULES
    # ──────────────────────────────────────────────────────────────────────────
    # btrfs is built into the mainline kernel — no extra module needed.
    # Add any hardware-specific modules here if required.
    # ──────────────────────────────────────────────────────────────────────────
    #kernelModules = [ ];

    # ──────────────────────────────────────────────────────────────────────────
    # VENTOY AND OTHER FILESYSTEMS
    # ──────────────────────────────────────────────────────────────────────────
    # CONSIDER:
    #services.udev.packages = [ pkgs.usbutils ];
    # ──────────────────────────────────────────────────────────────────────────
    supportedFilesystems = [
      "ntfs"
      "exfat"
      "vfat"
    ];
  };

  # ────────────────────────────────────────────────────────────────────────────
  # 2. EFI PARTITION MOUNT
  # ────────────────────────────────────────────────────────────────────────────
  # Declaring /boot here (in addition to hardware-configuration.nix) serves
  # two purposes:
  #
  #   a) Reproducibility — hardware-configuration.nix is auto-generated by
  #      nixos-generate-config and can be regenerated/overwritten. Keeping
  #      the authoritative mount options here means a regenerated hardware
  #      config doesn't silently regress security or mount behaviour.
  #
  #   b) Hardened options — the generated config uses fmask=0022/dmask=0022
  #      (world-readable). We override to 0077 (owner/root-only), which is
  #      correct for an EFI partition.
  #
  # UUID confirmed from: blkid /dev/sda2
  # Short hex format is correct for FAT32 (e.g. 0389-4D77).
  # ────────────────────────────────────────────────────────────────────────────
  fileSystems."/boot" = lib.mkForce {
    # ──────────────────────────────────────────────────────────────────────────
    # Identify by UUID — stable across device reorders.
    # ──────────────────────────────────────────────────────────────────────────
    device = "/dev/disk/by-uuid/0389-4D77";

    fsType = "vfat";

    options = [
      # ────────────────────────────────────────────────────────────────────────
      # fmask: permission mask for FILES on the FAT partition.
      # 0077 = owner has full access; group and other have none.
      # Prevents other users from reading EFI binaries or grub.cfg.
      # ────────────────────────────────────────────────────────────────────────
      "fmask=0077"

      # ────────────────────────────────────────────────────────────────────────
      # dmask: permission mask for DIRECTORIES on the FAT partition.
      # Same reasoning as fmask.
      # ────────────────────────────────────────────────────────────────────────
      "dmask=0077"

      # ────────────────────────────────────────────────────────────────────────
      # Standard FAT32 / EFI compatibility options.
      # ────────────────────────────────────────────────────────────────────────
      "codepage=437"
      "iocharset=iso8859-1"
      "shortname=mixed"

      # ────────────────────────────────────────────────────────────────────────
      # On encountering filesystem errors, remount read-only rather
      # than continuing writes to a potentially corrupt volume.
      # This is the FAT32 default behaviour but stating it explicitly
      # makes the intent clear.
      # ────────────────────────────────────────────────────────────────────────
      "errors=remount-ro"
    ];
  };

  # ────────────────────────────────────────────────────────────────────────────
  # 3. BOOT PARTITION HEALTH CHECK
  # ────────────────────────────────────────────────────────────────────────────
  # A systemd oneshot service that runs early in the boot sequence and
  # verifies that /boot is mounted, writable, and not critically low on space.
  #
  # WHY: FAT32 has no journaling. An unclean unmount (power loss, forced
  # reboot mid-write) can corrupt the allocation table silently. The kernel
  # auto-remounts a corrupted FAT partition read-only as a safety measure.
  # When this happens mid-rebuild, it produces a confusing
  # "Read-only file system" error rather than "filesystem is corrupt".
  # This service surfaces the problem at boot, before any rebuild is attempted.
  #
  # Check the service status with:
  #   systemctl status boot-partition-health
  #   journalctl -u boot-partition-health
  # ────────────────────────────────────────────────────────────────────────────
  systemd.services.boot-partition-health = {
    description = "Boot partition (/boot) health check";

    # ──────────────────────────────────────────────────────────────────────────
    # Run after filesystems are mounted but before most services start.
    # ──────────────────────────────────────────────────────────────────────────
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      # ────────────────────────────────────────────────────────────────────────
      # oneshot: run once at boot and exit. The service is considered
      # active (green) as long as it exited 0.
      # ────────────────────────────────────────────────────────────────────────
      Type = "oneshot";

      # ────────────────────────────────────────────────────────────────────────
      # Keep the service queryable after it exits so systemctl status
      # and journalctl can report pass/fail after boot.
      # ────────────────────────────────────────────────────────────────────────
      RemainAfterExit = true;
    };

    script = ''
      echo "=== /boot partition health check ==="

      # ── 1. Confirm /boot is mounted ──────────────────────────────────
      if ! ${pkgs.util-linux}/bin/mountpoint -q /boot; then
        echo "FAIL: /boot is not mounted." >&2
        echo "      Check fileSystems configuration and dmesg for mount errors." >&2
        exit 1
      fi
      echo "PASS: /boot is mounted."

      # ── 2. Confirm /boot is writable ────────────────────────────────
      # A read-only /boot means FAT corruption was detected by the kernel.
      # Do not attempt a rebuild — repair first with fsck.fat from a live ISO.
      if ! touch /boot/.write-test 2>/dev/null; then
        echo "FAIL: /boot is read-only." >&2
        echo "      Likely FAT32 corruption. Boot a NixOS ISO and run:" >&2
        echo "        fsck.fat -a /dev/disk/by-uuid/0389-4D77" >&2
        exit 1
      fi
      rm -f /boot/.write-test
      echo "PASS: /boot is writable."

      # ── 3. Check available space ────────────────────────────────────
      # Warn if less than 40 MB free. A full /boot causes write failures
      # identical in appearance to FAT corruption failures.
      # Run: sudo nix-collect-garbage -d   to reclaim old generations.
      AVAIL=$(${pkgs.coreutils}/bin/df -m /boot | ${pkgs.gawk}/bin/awk 'NR==2 {print $4}')
      echo "INFO: /boot available space: ''${AVAIL} MB"

      if [ "''${AVAIL}" -lt 40 ]; then
        echo "WARN: /boot is critically low on space (''${AVAIL} MB free)." >&2
        echo "      Run: sudo nix-collect-garbage -d" >&2
        echo "      Then: cypher-rebuild  (to reinstall bootloader with pruned generations)" >&2
        # Warn but do not exit non-zero — low space is not yet a hard failure.
      fi

      echo "=== /boot health check complete ==="
    '';
  };

  # ────────────────────────────────────────────────────────────────────────────
  # 4. CYPHER-REBUILD SCRIPT
  # ────────────────────────────────────────────────────────────────────────────
  # A system-wide rebuild command that always includes --install-bootloader.
  #
  # WHY --install-bootloader ON EVERY REBUILD:
  #   nixos-rebuild boot/switch does NOT reinstall the bootloader by default.
  #   It updates grub.cfg (generation entries) but does not rewrite the EFI
  #   binary or NVRAM entry. If /boot was in a degraded state during a prior
  #   rebuild, the bootloader may be stale or missing entirely. The overhead
  #   of reinstalling on every rebuild is negligible (~1 second); the cost of
  #   not doing it is an unbootable system (INC-24-04-2026).
  #
  # USAGE:
  #   cypher-rebuild              # standard rebuild + bootloader reinstall
  #   cypher-rebuild --dry-run    # evaluate only, no changes
  #   cypher-rebuild --upgrade    # also runs nix flake update first
  #
  # The script passes all arguments through to nixos-rebuild, so any
  # valid nixos-rebuild flag works.
  # ────────────────────────────────────────────────────────────────────────────
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "cypher-rebuild" ''
      set -euo pipefail

      FLAKE_PATH="/home/cypher-whisperer/CYPHER_OS"
      FLAKE_TARGET="cypher-nixos"

      echo "→ cypher-rebuild: NixOS rebuild with bootloader reinstall"
      echo "  Flake: ''${FLAKE_PATH}#''${FLAKE_TARGET}"
      echo "  Extra args: $*"
      echo ""

      # Require root — nixos-rebuild needs it, and making it explicit
      # here gives a cleaner error than a buried permission denied.
      if [ "$(id -u)" -ne 0 ]; then
        echo "  Rerunning with sudo..."
        exec sudo "$0" "$@"
      fi

      ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot \
        --install-bootloader \
        --flake "''${FLAKE_PATH}#''${FLAKE_TARGET}" \
        "$@"

      echo ""
      echo "✓ Rebuild complete."
      echo "  Reboot to activate the new generation."
      echo "  To activate without rebooting (no bootloader change): use nixos-rebuild switch"
    '')
  ];
}
