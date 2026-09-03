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
  config,
  lib,
  ...
}:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {
    home.file.".local/share/backgrounds/default-gnome-bg.jpg" = {
      source = config.cypher-os.constants.defaultWallpaper;
    };

    home.file.".face" = {
      source = config.cypher-os.constants.userAvatar;
    };
  };
}
