# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/assets.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# GNOME assets: wallpaper and user avatar.
#
# Owns the home.file declarations that place static image assets into the
# user profile before GDM or the GNOME session reads dconf. Keeping these
# here guarantees the files exist at their dconf-referenced paths on every
# boot, solving the first-boot blank/black wallpaper problem.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.de.gnome;
  userAvatar = cypherOsConstants.userAvatar;
  wallpaperSrcPath = cypherOsConstants.defaultWallpaper.sourcePath;
  wallpaperTgtPath = cypherOsConstants.defaultWallpaper.targetPath;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    home.file.${wallpaperTgtPath} = {
      source = wallpaperSrcPath;
    };

    home.file.".face" = {
      source = userAvatar;
    };
  };
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: ADD ASSERTIONS TO ENSURE ASSETS EXIST AND ARE VALID.
# ──────────────────────────────────────────────────────────────────────────────
