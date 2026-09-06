# ──────────────────────────────────────────────────────────────────────────────
# src/xdg/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Owns two things:
#   1. XDG user dirs  — where standard dirs (Downloads, Videos, etc.) live.
#   2. GTK bookmarks  — what shows up in file manager sidebars across all DEs.
#
# ──────────────────────────────────────────────────────────────────────────────
# Applied everywhere for cross-DE consistency. File managers that respect
# ~/.config/gtk-3.0/bookmarks:
#   Nautilus, Dolphin, Thunar, Nemo, PCManFM — all of them.
#
# ──────────────────────────────────────────────────────────────────────────────
# Symlink XDG user dirs into @data so the standard dirs point at the data lake.
# These are written to ~/.config/user-dirs.dirs and respected by GNOME,
# file managers, and any app that calls xdg-user-dir.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.xdg;
  dataDirRoot = cypherOsConstants.backupRoot;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [
    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {

      # ────────────────────────────────────────────────────────────────────────
      # 1. ENSURING DIRECTORIES' PRESENCE
      # ────────────────────────────────────────────────────────────────────────
      home.activation.ensureCypherOsDataDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p \
          "${dataDirRoot}/dox" \
          "${dataDirRoot}/Videos" \
          "${dataDirRoot}/DE_FILES/SHARED/Downloads" \
          "${dataDirRoot}/DE_FILES/SHARED/Pictures" \
          "${dataDirRoot}/Music" \
          "${dataDirRoot}/PROJECTS"
      '';

      # ────────────────────────────────────────────────────────────────────────
      # 2. XDG USER DIRECTORIES
      # ────────────────────────────────────────────────────────────────────────
      # xdg.userDirs is a Home Manager option available in
      # home-manager/modules/misc/xdg.nix. In NixOS, the system-wide
      # configuration must use environment.etc."xdg/user-dirs.defaults" to set
      # default directory paths, but this does not automatically create the
      # directories for existing users without manual invocation of
      # xdg-user-dirs-update.
      #
      # ────────────────────────────────────────────────────────────────────────
      # For Home Manager configurations, xdg.userDirs is the correct and
      # supported method, allowing users to enable, disable, and customize
      # directories like download, documents, and pictures.
      #
      # ────────────────────────────────────────────────────────────────────────
      # Writes ~/.config/user-dirs.dirs. Respected by GNOME, all file managers,
      # and any app that calls xdg-user-dir at runtime.
      # createDirectories is set to false because @data is a BTRFS subvolume
      # that already exists at mount time — letting HM recreate them would fight
      # the mount.
      # ────────────────────────────────────────────────────────────────────────
      xdg.userDirs = {
        enable = true;
        createDirectories = false;

        desktop = dataDirRoot; # no separate Desktop dir — point at root
        templates = dataDirRoot; # same
        publicShare = dataDirRoot; # same
        documents = "${dataDirRoot}/dox";
        videos = "${dataDirRoot}/Videos";
        music = "${dataDirRoot}/Music";
        download = "${dataDirRoot}/DE_FILES/SHARED/Downloads";
        pictures = "${dataDirRoot}/DE_FILES/SHARED/Pictures";

        # ──────────────────────────────────────────────────────────────────────
        # extraConfig: non-standard dirs that apps sometimes read
        # ──────────────────────────────────────────────────────────────────────
        extraConfig = {
          XDG_PROJECTS_DIR = "${dataDirRoot}/PROJECTS";
          # XDG_MEGA_DIR = "$HOME/DATA/FILES/MEGA";
        };
      };

      # ────────────────────────────────────────────────────────────────────────
      # 3. GTK BOOKMARKS
      # ────────────────────────────────────────────────────────────────────────
      # Format per line:
      # ────────────────────────────────────────────────────────────────────────
      #   file:///absolute/path
      #   file:///absolute/path Optional Display Label
      #
      # ────────────────────────────────────────────────────────────────────────
      # Rules:
      # ────────────────────────────────────────────────────────────────────────
      #   • Path must be absolute — no $HOME, no ~ (file managers expand
      #     literally). Use config.home.homeDirectory to get the runtime home
      #     path from Nix.
      #
      #   • Label is optional. Without it, the file manager shows the directory
      #     name. With it, you can write anything — "📥 Downloads", "Projects",
      #     etc.
      #
      #   • Order in this file = order in the sidebar. Be intentional.
      #
      #   • Blank lines and comments are NOT valid in the bookmarks file
      #     itself — only in this Nix heredoc. The `text` value below is the
      #     rendered file.
      #
      #   • Icons: you cannot set icons here. File managers assign icons based
      #     on whether the path matches a known XDG dir (auto-icon) or falls
      #     back to a generic folder. To get custom icons on non-XDG dirs, you'd
      #     need a .directory file inside each folder — out of scope here,
      #     future enhancement.
      #
      # ────────────────────────────────────────────────────────────────────────
      # To add a bookmark:
      # ────────────────────────────────────────────────────────────────────────
      #   1. Add a line: file://${home}/DATA/FILES/YOUR_PATH Optional Label
      #
      # To add a section separator (supported by Nautilus,
      # not all file managers): Some file managers treat consecutive bookmarks
      # as grouped. There is no official separator syntax in the GTK bookmarks
      # format — grouping is visual only via ordering.
      # ────────────────────────────────────────────────────────────────────────

      xdg.configFile."gtk-3.0/bookmarks" = {
        text = ''
          file://${dataDirRoot}/dox Documents
          file://${dataDirRoot}/DE_FILES/SHARED/Downloads Downloads
          file://${dataDirRoot}/DE_FILES/SHARED/Pictures Pictures
          file://${dataDirRoot}/Videos Videos
          file://${dataDirRoot}/PROJECTS Projects
          file://${dataDirRoot} Vault
          file://${dataDirRoot}/Music Music
        '';
        # Uncomment to add more — examples:
        # file://${dataDirRoot}/MEGA MEGA
        # file://${dataDirRoot}/DEV Dev
      };
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.xdg.enable = lib.mkDefault (cypherOsProfile == "desktop");
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.de.xdg.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: Adding custom display icons for bookmarks as stated in the comment above.
# ──────────────────────────────────────────────────────────────────────────────
