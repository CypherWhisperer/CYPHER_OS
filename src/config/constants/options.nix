# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/options.nix
# ──────────────────────────────────────────────────────────────────────────────
# Declares cypher-os.constants.* — see ADR-023's constants section and the
# runbook RBK-013 ("Adding or Updating a Constant").
#
# NixOS-context only for now (no hm.nix yet)
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.constants = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user's login name — see ADR-014.";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      description = "Primary user's home directory path — see ADR-014.";
    };

    primaryDisk = lib.mkOption {
      type = lib.types.str;
      description = "Block device path of the primary disk (e.g. /dev/sda).";
    };

    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "Shared system.stateVersion / home.stateVersion value.";
    };

    backupRoot = lib.mkOption {
      type = lib.types.str;
      description = "Root directory for personal, backup-able data. Defaults relative to homeDirectory.";
    };

    obsidianVaultRoot = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to the Obsidian vault. Defaults relative to backupRoot.
      '';
    };

    userAvatar = lib.mkOption {
      type = lib.types.path;
      description = "Default user avatar image, sourced from the repo's assets directory.";
    };

    defaultWallpaper = lib.mkOption {
      type = lib.types.path;
      description = "Default desktop wallpaper image, sourced from the repo's assets directory.";
    };
  };
}
