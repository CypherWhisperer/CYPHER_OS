# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.de.gnome;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # desktopManager.gnome.enable pulls in gnome-shell, gnome-session,
    # gnome-control-center, nautilus, and the core GNOME session infrastructure.
    # It does NOT pull in every GNOME app — that's controlled separately below.
    # ──────────────────────────────────────────────────────────────────────────
    services.desktopManager.gnome.enable = true;

    # ──────────────────────────────────────────────────────────────────────────
    # GNOME BLOATWARE EXCLUSION
    # ──────────────────────────────────────────────────────────────────────────
    # services.desktopManager.gnome.enable pulls in a default set of GNOME apps.
    # environment.gnome.excludePackages lets us surgically remove the ones not
    # desired, hence a minimal GNOME.
    #
    # Everything listed would otherwise be installed system-wide automatically.
    # ──────────────────────────────────────────────────────────────────────────
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour # first-run tour wizard — not needed
      yelp # GNOME help browser — documentation you'll never open
      totem # GNOME Videos — you use vlc
      gnome-maps # GNOME Maps
      gnome-weather # GNOME Weather widget
      gnome-contacts # GNOME Contacts
      gnome-music # GNOME Music — you use spotify
      epiphany # GNOME Web (built-in browser) — you use brave/firefox
      geary # GNOME Mail client — you use proton-mail
      gnome-calendar
      simple-scan # scanner app — keep if thou have a scanner, exclude if not
      gnome-clocks # keep or exclude based on preference
      gnome-console
      # gnome-characters   # character/emoji picker — borderline useful
    ];
  };
}
