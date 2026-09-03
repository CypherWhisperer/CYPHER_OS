# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/theming.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# GNOME theming: GTK theme, cursor, fonts, and libadwaita (GTK4) assets.
#
# GNOME theming: GTK3/GTK4/libadwaita theming via Fausto-Korpsvart's
# Catppuccin GTK Theme (https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme),
# plus cursor, fonts, and dconf accent settings.
#
# ──────────────────────────────────────────────────────────────────────────────
# Why Fausto-Korpsvart instead of pkgs.catppuccin-gtk?
#   nixpkgs catppuccin-gtk package (upstream: catppuccin/gtk) has been archived.
#
#   Fausto-Korpsvart's port is actively maintained, GNOME-focused, and crucially
#   overrides libadwaita's CSS custom properties (--accent-bg-color, etc.) so
#   that GTK4/libadwaita apps receive true Catppuccin colours —
#   not just a dark fallback.
#
# Sources:
#   https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.cypher-os.de.gnome;

  # ────────────────────────────────────────────────────────────────────────────
  # CATPPUCCIN THEME CONFIGURATION: OLDSCHOOL
  # ────────────────────────────────────────────────────────────────────────────
  # Valid accents: rosewater flamingo pink mauve red maroon peach yellow
  #               green teal sky sapphire blue lavender
  # ctpAccent = "mauve";
  # ctpVariant = "mocha"; # ← latte | frappe | macchiato | mocha
  # ctpSize = "standard"; # ← standard | compact

  # The exact directory name the catppuccin-gtk package installs under
  # /share/themes/.
  # ctpThemeName = "Catppuccin-${lib.strings.toUpper (lib.strings.substring 0 1 ctpVariant)}${
  #   lib.strings.substring 1 (-1) ctpVariant
  # }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpSize)}${
  #   lib.strings.substring 1 (-1) ctpSize
  # }-${lib.strings.toUpper (lib.strings.substring 0 1 ctpAccent)}${
  #   lib.strings.substring 1 (-1) ctpAccent
  # }-Dark";

  # The overridden package, referenced by gtk.theme.package and home.file sources
  # ctpGtkPkg = pkgs.catppuccin-gtk.override {
  #   accents = [ ctpAccent ];
  #   size = ctpSize;
  #   tweaks = [ "normal" ]; # normal = standard window buttons (max/min/close)
  #   variant = ctpVariant;
  # };

  # ────────────────────────────────────────────────────────────────────────────
  # CATPPUCCIN THEME CONFIGURATION: NEW SCHOOL
  # ────────────────────────────────────────────────────────────────────────────
  # THEME PARAMETERS
  # ────────────────────────────────────────────────────────────────────────────
  # Accent maps to Fausto-Korpsvart's --theme flag.
  #   - Valid accents: default|purple|pink|red|orange|yellow|green|teal|grey
  #   - "purple" is the closest available to Catppuccin's mauve.
  # ────────────────────────────────────────────────────────────────────────────
  fkVariant = "mocha"; # → passed via --tweaks (frappe|macchiato; default->mocha)
  fkAccent = "mauve";
  # fkMode = "dark";

  # ────────────────────────────────────────────────────────────────────────────
  # The theme name as installed by the script. Fausto-Korpsvart's install.sh
  # Constructed per install.sh: ${name}${ctype}${theme}${color}${size}${tweaks_tag}
  #   - ctype="" (mocha is default),
  #   - theme="-Mauve",
  #   - color="-Dark",
  #   - size="" (standard),
  #   - tweaks_tag=""
  # ────────────────────────────────────────────────────────────────────────────
  fkThemeName = "Catppuccin-Mauve-Dark";

  # ────────────────────────────────────────────────────────────────────────────
  # DERIVATION — compile Fausto-Korpsvart theme from source
  # - Requires sassc @ build time.
  # - The install script writes to --dest; we capture that as $out/share/themes.
  # ────────────────────────────────────────────────────────────────────────────
  fkGtkPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "catppuccin-gtk-fausto-${fkVariant}-${fkAccent}";
    version = "unstable-2025";

    src = pkgs.fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Catppuccin-GTK-Theme";

      # ────────────────────────────────────────────────────────────────────────
      # Pin to a specific commit for reproducibility.
      # Update this rev + hash after verifying a new upstream commit.
      # ────────────────────────────────────────────────────────────────────────
      rev = "35695ce73854ec59342a34abe7ef0684be1138dd"; # "HEAD"

      # ────────────────────────────────────────────────────────────────────────
      # Replace accordingly. e.g:
      # nix-prefetch-url --unpack https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme/archive/HEAD.tar.gz
      # ────────────────────────────────────────────────────────────────────────
      hash = "sha256-WV9uMOd88GR8i77PEr1UyJFacIP1tXu1p9uDVxfYy6M=";
    };

    nativeBuildInputs = with pkgs; [
      sassc # SCSS compiler — required by install.sh
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # install.sh sets REPO_DIR=$(dirname $0), so it must be invoked from within
    # themes/ for the relative SRC_DIR/LIB_DIR paths to resolve correctly.
    #
    # --libadwaita is intentionally omitted:
    #   - it tries to symlink into $HOME/.config/gtk-4.0 which is a side-effect
    #     incompatible with a Nix sandbox.
    #   - We handle gtk-4.0 assets separately via xdg.configFile below.
    # ──────────────────────────────────────────────────────────────────────────
    installPhase = ''
      runHook preInstall

      # install.sh expects a writable HOME for temporary files
      # install.sh may write temp files relative to $HOME
      export HOME=$(mktemp -d)

      # Bypassing interactive menu - nix sandbox doesn't support such.
      export BATCH_MODE=true

      mkdir -p $out/share/themes

      # install.sh is inside themes/ subdirectory - Not repo root
      cd themes

      bash install.sh \
        --dest    "$out/share/themes" \
        --name    "Catppuccin" \
        -a mauve \
        -m dark

      # --libadwaita symlinks gtk-4.0 into $HOME/.config/gtk-4.0 — we don't
      # want that side-effect in a Nix build. The gtk-4.0 assets inside
      # $out/share/themes/*/gtk-4.0/ are what we reference below via home.file.

      runHook postInstall
    '';

    meta = {
      description = "Catppuccin GTK theme by Fausto-Korpsvart (Mocha/Mauve)";
      homepage = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };

in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # Required for Layer 2: (GNOME Shell theme). Provides the user-theme
      # extension that reads org/gnome/shell/extensions/user-theme.name from dconf.
      # ────────────────────────────────────────────────────────────────────────
      gnomeExtensions.user-themes
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # GTK THEME, ICONS, CURSOR, FONTS
    # ──────────────────────────────────────────────────────────────────────────
    # adw-gtk3: backports the libadwaita (GTK4) look to GTK3 apps, so older apps
    # look consistent with native GNOME apps. Toggle to
    # "Adwaita" + pkgs.gnome.adwaita-icon-theme for pure classic look.
    #
    # Layer 1: GTK3 apps (Nautilus widget chrome, most older GNOME apps)
    #
    # Layer 3: GTK4/Libadwaita (Settings, Text Editor) — handled via home.file
    #          below because libadwaita ignores gtk.theme and reads
    #          ~/.config/gtk-4.0/gtk.css
    #
    # ──────────────────────────────────────────────────────────────────────────
    # GTK3 THEME
    #   - Applies to GTK3 apps (Nautilus chrome, legacy GNOME apps, LibreOffice
    #     via SAL_USE_VCLPLUGIN=gtk3).
    # ──────────────────────────────────────────────────────────────────────────
    gtk = {
      enable = true;
      theme = {

        # ──────────────────────────────────────────────────────────────────────
        # GTK3Dark variant -> "adw-gtk3-dark"
        # Old School -> "ctpThemeName"
        # ──────────────────────────────────────────────────────────────────────
        name = fkThemeName;

        # ──────────────────────────────────────────────────────────────────────
        # GTK3 -> pkgs.adw-gtk3
        # Old School -> "ctpGtkPkg"
        # ──────────────────────────────────────────────────────────────────────
        package = fkGtkPkg;
      };

      # ────────────────────────────────────────────────────────────────────────
      # SILENCE HOME MANAGER 26.05 EVALUATION WARNING.
      # ────────────────────────────────────────────────────────────────────────
      # GTK4 theme — set to match GTK3 to silence the HM 26.05 warning and keep
      # legacy behaviour. HM writes gtk-4.0/gtk.css automatically from this pkg.
      #
      # Do NOT also declare home.file."gtk-4.0/gtk.css" — that causes a conflict
      # ────────────────────────────────────────────────────────────────────────
      gtk4.theme = {

        # ──────────────────────────────────────────────────────────────────────
        # Old School: -> ctpThemeName
        # ──────────────────────────────────────────────────────────────────────
        name = fkThemeName;

        # ──────────────────────────────────────────────────────────────────────
        # Old School: -> ctpGtkPkg
        # ──────────────────────────────────────────────────────────────────────
        package = fkGtkPkg;
      };

      # ────────────────────────────────────────────────────────────────────────
      # NOTE: Letting catppuccin/nix handle the icon and cursor themes globally
      #       for consistency across DEs and apps.
      # ────────────────────────────────────────────────────────────────────────
      #
      # iconTheme = {
      #   # ────────────────────────────────────────────────────────────────────
      #   # catppuccin-papirus-folders: Papirus icon set with
      #   # Catppuccin-coloured folders. The accent here must be prefixed with
      #   # "cat-mocha-" for the override to pick the right folder colour set.
      #   # ────────────────────────────────────────────────────────────────────
      #   name = "Papirus-Dark"; # ADWAITA -> "Adwaita"
      #   package = pkgs.catppuccin-papirus-folders.override {
      #     flavor = ctpVariant; # mocha
      #     accent = ctpAccent; # mauve
      #     # ADWAITA -> pkgs.adwaita-icon-theme
      #   };
      # };
      # ────────────────────────────────────────────────────────────────────────

      cursorTheme = {

        # ──────────────────────────────────────────────────────────────────────
        # CATPPUCCIN
        # ──────────────────────────────────────────────────────────────────────
        # catppuccin-cursors is an attribute set of pre-built cursor packages.
        # The attribute name is camelCase: mocha + Dark = mochaDark.
        # The cursor theme name string (what GNOME reads) is title-case with
        # spaces: "Catppuccin Mocha Dark"
        # ──────────────────────────────────────────────────────────────────────
        # name = "Catppuccin Mocha Dark";
        # package = pkgs.catppuccin-cursors.mochaDark;

        # ──────────────────────────────────────────────────────────────────────
        # ADWAITA
        # ──────────────────────────────────────────────────────────────────────
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
      };

      font = {
        name = "Cantarell";
        size = 11;
      };

      gtk4.extraConfig = { };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # LAYER 3: LIBADWAITA (GTK4) THEMING
    # ──────────────────────────────────────────────────────────────────────────
    # home.file.".config/gtk-4.0/gtk.css".source =
    # "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/gtk.css";
    #
    # home.file.".config/gtk-4.0/gtk-dark.css".source =
    # "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/gtk-dark.css";
    #
    # home.file.".config/gtk-4.0/assets" = {
    # recursive = true;
    # source    = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";
    # };
    #
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE:
    #  - the xdg.configFile."gtk-4/assets" below achieves the same thing as
    #    the lines above. Together they conflict.
    #
    #  - HM's gtk module writes gtk.css and gtk-dark.css automatically. Only
    #    assets/ needs an explicit declaration — the gtk module doesn't copy it.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."gtk-4.0/assets" = {
      recursive = true;

      # ────────────────────────────────────────────────────────────────────────
      # Old School:
      # ────────────────────────────────────────────────────────────────────────
      # source = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";
      # ────────────────────────────────────────────────────────────────────────
      source = "${fkGtkPkg}/share/themes/${fkThemeName}/gtk-4.0/assets";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # DCONF — interface settings
    # ──────────────────────────────────────────────────────────────────────────
    dconf.settings = {

      enabled-extensions = [
        # ──────────────────────────────────────────────────────────────────────
        # Layer 2: GNOME Shell chrome (top bar, overview,
        # notifications). user-theme extension reads from
        # org/gnome/shell/extensions/user-theme and applies a shell theme from
        # ~/.themes or the system themes directory.
        # ──────────────────────────────────────────────────────────────────────
        "user-theme@gnome-shell-extensions.gcampax.github.com"
      ];

      # ────────────────────────────────────────────────────────────────────────
      # Layer 2: GNOME Shell theme (top bar, overview, notifications, dash).
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/user-theme" = {
        # ──────────────────────────────────────────────────────────────────────
        # Old School: -> ctpThemeName
        # ──────────────────────────────────────────────────────────────────────
        name = fkThemeName;
      };

      "org/gnome/desktop/interface" = {

        color-scheme = "prefer-dark";

        # ──────────────────────────────────────────────────────────────────────
        # gtk-theme tells GTK3 apps which theme to load.
        # Must match gtk.theme.name exactly.
        #
        # ADWAITA -> "adw-gtk3";
        # Old School: -> ctpThemeName
        # ──────────────────────────────────────────────────────────────────────
        gtk-theme = fkThemeName;

        # ──────────────────────────────────────────────────────────────────────
        # GNOME 47+ native accent-color — fallback for apps that read this key
        # directly instead of the GTK CSS.
        #
        # Does not override libadwaita CSS; both work together.
        # ──────────────────────────────────────────────────────────────────────
        accent-color = "blue";

        # ──────────────────────────────────────────────────────────────────────
        # CURSOR THEME
        # ──────────────────────────────────────────────────────────────────────
        # ──────────────────────────────────────────────────────────────────────
        # CATPPUCCIN
        # ──────────────────────────────────────────────────────────────────────
        # cursor-theme = "Catppuccin Mocha Dark";
        # ──────────────────────────────────────────────────────────────────────
        #
        # ──────────────────────────────────────────────────────────────────────
        # ADWAITA
        # ──────────────────────────────────────────────────────────────────────
        cursor-theme = "Adwaita";
        cursor-size = 24;

        # ──────────────────────────────────────────────────────────────────────
        # ICON THEME
        # ──────────────────────────────────────────────────────────────────────
        # letting catppuccin/nix handle the icon and cursor themes globally
        # for consistency across DEs and apps.
        #
        # icon-theme = "Papirus-Dark"; # ADWAITA -> "Adwaita";
        # ──────────────────────────────────────────────────────────────────────
      };

      # ────────────────────────────────────────────────────────────────────────
      # Enforde Dark Mode at XDG portal level
      # ────────────────────────────────────────────────────────────────────────
      "org/freedesktop/appearance" = {
        color-scheme = lib.hm.gvariant.mkUint32 1; # the value 1 does the magic
      };
    };
  };
}
