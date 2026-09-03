# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/extensions.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# GNOME Shell extensions: packages, enabled UUIDs, and per-extension dconf keys.
#
# Owns the full extension package list, the enabled-extensions UUID list,
# and all per-extension dconf configuration blocks.The enabled-extensions list
# and package list must stay in sync — an enabled UUID with no installed package
# errors on load; an installed but unlisted package is silently inactive.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ────────────────────────────────────────────────────────────────────────────
  # Patched extension: compact-quick-settings
  # ────────────────────────────────────────────────────────────────────────────
  # Upstream metadata.json only declares shell-version up to "47". GNOME 50+
  # silently refuses to load extensions whose declared versions don't include
  # the running shell. This override patches metadata.json at build time to
  # add "50+" to the shell-version list, allowing GNOME 50+ to load it.
  # Remove this override once the upstream package ships a GNOME 50+ release.
  # ────────────────────────────────────────────────────────────────────────────
  compactQsExt = pkgs.gnomeExtensions.compact-quick-settings.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      metadata="$out/share/gnome-shell/extensions/compact-quick-settings@gnome-shell-extensions.mariospr.org/metadata.json"
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq '.["shell-version"] += ["48", "49", "50"]' "$metadata" > "$tmp"
      mv "$tmp" "$metadata"
    '';
  });
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # GNOME Shell Extensions
      # ────────────────────────────────────────────────────────────────────────

      # ────────────────────────────────────────────────────────────────────────
      # blur-my-shell covers the core blur use case (panel, overview, appfolder).
      # ────────────────────────────────────────────────────────────────────────
      gnomeExtensions.blur-my-shell
      gnomeExtensions.burn-my-windows
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.compiz-alike-magic-lamp-effect
      gnomeExtensions.compiz-windows-effect
      gnomeExtensions.coverflow-alt-tab
      gnomeExtensions.desktop-cube
      gnomeExtensions.hide-top-bar
      gnomeExtensions.logo-menu
      gnomeExtensions.transparent-top-bar-adjustable-transparency
      gnomeExtensions.compiz-windows-effect
      gnomeExtensions.appindicator
      gnome-extension-manager

      #gnomeExtensions.compact-quick-settings
      compactQsExt # the patched version of compact-quick-settings

      #gnomeExtensions.appimage-manager
      #gnomeExtensions.window-state-manager
      #gnomeExtensions.workspace-switcher-manager
      #gnomeExtensions.tweaks-in-system-menu
    ];

    dconf.settings = {
      # ────────────────────────────────────────────────────────────────────────
      # Shell: Enabled Extensions
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell" = {

        # ──────────────────────────────────────────────────────────────────────
        # The UUID list tells GNOME Shell which extensions to load on startup.
        # Each string must exactly match the UUID in the extension's
        # metadata.json.
        # ──────────────────────────────────────────────────────────────────────
        enabled-extensions = [
          "blur-my-shell@aunetx"
          "burn-my-windows@schneegans.github.com"
          "clipboard-indicator@tudmotu.com"
          "compact-quick-settings@gnome-shell-extensions.mariospr.org"
          "compiz-alike-magic-lamp-effect@hermes83.github.com"
          "compiz-windows-effect@hermes83.github.com"
          "CoverflowAltTab@palatis.blogspot.com"
          "desktop-cube@schneegans.github.com"
          "hidetopbar@mathieu.bidon.ca"
          "logomenu@aryan_k"
          "transparent-top-bar@zhanghai.me"
          "wobbly-windows@mecheye.net"
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: hide-top-bar
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/hidetopbar" = {
        enable-active-window = true;
        enable-intellihide = true;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: blur-my-shell
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/blur-my-shell" = {
        settings-version = 2;
      };

      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
        brightness = 0.6;
        sigma = 30;
      };

      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        brightness = 0.6;
        sigma = 30;
        static-blur = true;
        style-dash-to-dock = 0;
      };

      "org/gnome/shell/extensions/blur-my-shell/window-list" = {
        brightness = 0.6;
        sigma = 30;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: logo-menu
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/Logo-menu" = {
        menu-button-icon-image = 19;
        symbolic-icon = true;
        use-custom-icon = false;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: coverflow-alt-tab
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/coverflowalttab" = {
        switcher-background-color = lib.hm.gvariant.mkTuple [
          1.0
          1.0
          1.0
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: compiz-windows-effect
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/com/github/hermes83/compiz-windows-effect" = {
        last-version = 29;
        preset = "R";
      };

      # ────────────────────────────────────────────────────────────────────────
      # Extension: clipboard-indicator
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell/extensions/clipboard-indicator" = {
        notify-on-copy = true;
      };
    };
  };
}
