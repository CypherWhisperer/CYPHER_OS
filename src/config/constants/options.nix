# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/options.nix
# ──────────────────────────────────────────────────────────────────────────────
# Declares cypher-os.constants.* — see ADR-023's constants section and the
# runbook RBK-013 ("Adding or Updating a Constant").
#
# NixOS-context only for now (no hm.nix yet)
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  self,
  ...
}:
{
  options.cypher-os.constants = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user's login name — see ADR-014.";
    };

    userId = lib.mkOption {
      type = lib.types.ints.unsigned;
      description = "Primary user's UUID value. Same across OS lenses.";
    };

    displayName = lib.mkOption {
      type = lib.types.str;
      description = "Primary user's Display name";
    };

    primaryUserShell = lib.mkOption {
      type = lib.types.enum [
        "bash"
        "zsh"
        "fish"
        "nushell"
      ];
      description = ''
        The primary user's primary shell. "bash" is always valid regardless
        of cypher-os.shell.*'s state — it's the NixOS/Linux baseline, never
        gated behind an enable toggle (see src/shell/options.nix's own
        comment on this). The other three require their corresponding
        cypher-os.shell.{enable,<name>.enable} to both be true — enforced
        by src/users/cypher_whisperer.nix's assertion, not by this option's
        type.
      '';
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
      default = "24.11";
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

    gamingFiles = {
      root = lib.mkOption {
        type = lib.types.str;
        description = "Path to the parent directory hosting all Gaming related data under @data mount point.";
      };

      steamFiles = {
        root = lib.mkOption {
          type = lib.types.str;
          description = "Path to the parent directory hosting all Steam related data.";
        };

        dataRoot = lib.mkOption {
          type = lib.types.str;
          description = "Path to the parent directory hosting Steam data files.";
        };

        steamLibraryRoot = lib.mkOption {
          type = lib.types.str;
          description = "Path to the parent directory hosting Steam Library related files.";
        };

        xdgRoot = lib.mkOption {
          type = lib.types.str;
          description = "Path to the parent directory hosting Steam XDG relates files (Steam's expected XDG data location).";
        };
      };
    };

    userAvatar = lib.mkOption {
      type = lib.types.path;
      default = "${self}/src/de/assets/default-gnome-avatar.jpg";
      description = "Default user avatar image, sourced from the repo's assets directory.";
    };

    defaultWallpaper = lib.mkOption {
      type = lib.types.path;
      default = "${self}/src/de/assets/default-gnome-bg.jpg";
      description = "Default desktop wallpaper image, sourced from the repo's assets directory.";
    };

    zshPowerLevel10kThemeFile = lib.mkOption {
      type = lib.types.path;
      default = "${self}/src/shell/configs/p10k.zsh";
      description = "Path to the Powerlevel10k theme file for Zsh.";
    };

    fastfetchArtworkPngsRoot = lib.mkOption {
      type = lib.types.path;
      default = "${self}/src/pkgs/cli/configs/fastfetch_artwork_pngs";
      description = "Path to the Fastfetch Artwork Images.";
    };

    terminalFont = {
      pkgName = lib.mkOption {
        type = lib.types.str;
        description = "The nixpkgs package Name to the Font Family used in CypherOS terminals (Kitty and Ghostty).";
        default = "nerd-fonts.caskaydia-cove";
      };

      displayName = lib.mkOption {
        type = lib.types.str;
        description = "The display Name to the Font Family used in CypherOS terminals (Kitty and Ghostty).";
        default = "CaskaydiaCove Nerd Font Mono";
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # cypherIDE setup may require
    # ──────────────────────────────────────────────────────────────────────────
    cypherIdeRepoRoot = lib.mkOption {
      type = lib.types.path;
      default = "${self}/src/pkgs/dev/ide/configs/cypher_ide";
      description = ''
        Path to the the Root of CypherIDE's repository (i.e., submodule to CypherOS repository).
      '';
    };
  };
}
