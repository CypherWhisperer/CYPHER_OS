# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Home Manager module for the GNOME desktop environment.
#
# Home Manager module for GNOME desktop environment.
# Manages everything Gnome-specific: extensions, dconf settings, theming, fonts,
# the XDG profile launcher, and the gnome-specific packages
# The main module file imports and composes the smaller, focused modules in this
# directory: extensions.nix, dconf.nix, theming.nix, and assets.nix.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  lib,
  osConfig ? null,
  ...
}:

let
  cfg = config.cypher-os.de.gnome;
  activeProfile =
    if osConfig != null then osConfig.cypher-os.profile.active else config.cypher-os.profile.active;
in

{
  imports = [
    ./options.nix
    ./assets.nix
    ./dconf.nix
    ./theming.nix
    ./extensions.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # ──────────────────────────────────────────────────────────────────────────
      # XDG PROFILE LAUNCHER SCRIPT
      # ──────────────────────────────────────────────────────────────────────────
      home.file.".local/bin/launch-gnome" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # XDG Profile Launcher — GNOME
          # Managed by Home Manager (modules/de/gnome.nix). Do not edit manually.

          export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
          export XDG_DATA_HOME="$HOME/.local/share/profiles/gnome"
          export XDG_CACHE_HOME="$HOME/.cache/profiles/gnome"
          export XDG_STATE_HOME="$HOME/.local/state/profiles/gnome"

          exec gnome-session
        '';
      };
    })

    {
      config.cypher-os.de.gnome.enable = lib.mkDefault (activeProfile == "desktop");
    }

    {
      assertions = [
        {
          assertion = cfg.enable -> activeProfile == "desktop";
          message = ''
            cypher-os.de.gnome.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
