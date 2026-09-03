# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/dconf.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# GNOME dconf settings: interface, keyboard, power, workspaces, peripherals,
# wallpaper, Nautilus preferences, and app-grid folders.
#
# Owns all dconf keys that are not extension-specific. Extension dconf keys
# live in extensions.nix alongside the packages that need them.
# ──────────────────────────────────────────────────────────────────────────────

{ config, lib, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.de.gnome.enable {
    # ──────────────────────────────────────────────────────────────────────────
    # DCONF SETTINGS
    # ──────────────────────────────────────────────────────────────────────────
    # dconf is GNOME's configuration database. Every gsettings key ultimately
    # writes to dconf. Home Manager's dconf.settings block applies these
    # declaratively — no manual gsettings commands needed.
    #
    # Path mapping:
    #   dconf path:  /org/gnome/desktop/interface
    #   Nix key:     "org/gnome/desktop/interface"   (leading slash dropped)
    # ──────────────────────────────────────────────────────────────────────────
    dconf.settings = {

      # ────────────────────────────────────────────────────────────────────────
      # Interface
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/interface" = {
        clock-format = "24h";
        show-battery-percentage = false;
        font-name = "Cantarell 11";
        document-font-name = "Cantarell 11";
        monospace-font-name = "Monospace 11";
      };

      # ────────────────────────────────────────────────────────────────────────
      # Keyboard: Layout & XKB Remapping
      # ────────────────────────────────────────────────────────────────────────
      # ctrl:swapcaps   → Caps Lock ↔ Left Ctrl (swap physical keys)
      # menu:super       → Menu key becomes Super (Windows key)
      # altwin:menu_win  → Reinforces Menu→Super at XKB level
      #
      # sources: list of (type, layout) tuples. ('xkb', 'us') = US QWERTY.
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/input-sources" = {
        sources = [
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "us"
          ])
        ];
        xkb-options = [
          "ctrl:swapcaps"
          "menu:super"
          "altwin:menu_win"
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Window Manager Keybindings
      # ────────────────────────────────────────────────────────────────────────
      # Vim-style workspace navigation carried over from your Debian dconf dump.
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-1 = [ "<Control>1" ];
        switch-to-workspace-2 = [ "<Control>2" ];
        switch-to-workspace-3 = [ "<Control>3" ];
        switch-to-workspace-4 = [ "<Control>4" ];
        switch-to-workspace-left = [ "<Control>h" ];
        switch-to-workspace-right = [ "<Control>l" ];
        switch-to-workspace-up = [ "<Control><Alt>Up" ];
        switch-to-workspace-down = [ "<Control><Alt>Down" ];
        move-to-workspace-left = [ "<Control><Shift>h" ];
        move-to-workspace-right = [ "<Control><Shift>l" ];
        move-to-workspace-up = [ "<Control><Shift><Alt>Up" ];
        move-to-workspace-down = [ "<Control><Shift><Alt>Down" ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Workspace Behaviour
      # ────────────────────────────────────────────────────────────────────────
      # dynamic-workspaces: GNOME auto-creates/removes workspaces.
      # num-workspaces: upper bound (11 matches your Debian setup).
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/mutter" = {
        dynamic-workspaces = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 11;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Power Management
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/session" = {
        # idle-delay = 0: never auto-dim or lock from inactivity alone.
        idle-delay = lib.hm.gvariant.mkUint32 0;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        power-button-action = "suspend";
        sleep-inactive-ac-type = "nothing"; # never sleep on AC
        sleep-inactive-battery-timeout = 900; # 15 min on battery
        sleep-inactive-battery-type = "nothing";
      };

      # ────────────────────────────────────────────────────────────────────────
      # Night Light
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false; # manual schedule, not auto-timezone
      };

      # ────────────────────────────────────────────────────────────────────────
      # Touchpad
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/peripherals/touchpad" = {
        natural-scroll = true;
        two-finger-scrolling-enabled = true;
        click-method = "fingers";
        speed = 0.45531914893617031;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Mouse
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/peripherals/mouse" = {
        natural-scroll = false;
        speed = 0.4893617021276595;
      };

      # ────────────────────────────────────────────────────────────────────────
      # Wallpaper
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/background" = {
        picture-uri = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-uri-dark = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-options = "zoom";
        color-shading-type = "solid";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };

      "org/gnome/desktop/screensaver" = {
        picture-uri = "file:///home/cypher-whisperer/.local/share/backgrounds/default-gnome-bg.jpg";
        picture-options = "zoom";
        color-shading-type = "solid";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };

      # ────────────────────────────────────────────────────────────────────────
      # Dash Favorites
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: (RFC: Check App Installation Status; prevents broken icons in dash)
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/shell" = {

        # ──────────────────────────────────────────────────────────────────────
        # The dash/dock favorites list. These are .desktop file names — GNOME
        # looks them up in the applications directories from the OS's PATH.
        #
        #  - Order here = left-to-right order in the dash.
        #  - Apps not installed produce a broken icon; remove or install the app
        # ──────────────────────────────────────────────────────────────────────
        favorite-apps = [

          # ────────────────────────────────────────────────────────────────────
          # browser
          # ────────────────────────────────────────────────────────────────────
          "brave-browser.desktop"
          "librewolf.desktop"
          "firefox.desktop"
          "mullvad-browser.desktop"
          "torbrowser.desktop"

          # ────────────────────────────────────────────────────────────────────
          # communication
          # ────────────────────────────────────────────────────────────────────
          "thunderbird.desktop"
          "discord.desktop"
          "io.github.tobagin.karere.desktop"
          "org.telegram.desktop.desktop"
          "signal.desktop"

          # ────────────────────────────────────────────────────────────────────
          # development
          # ────────────────────────────────────────────────────────────────────
          "code.desktop"
          "antigravity.desktop"
          "cursor.desktop"
          "webstorm.desktop"
          "android-studio.desktop"

          # ────────────────────────────────────────────────────────────────────
          # terminal
          # ────────────────────────────────────────────────────────────────────
          "com.mitchellh.ghostty.desktop"
          "kitty.desktop"

          # ────────────────────────────────────────────────────────────────────
          # productivity
          # ────────────────────────────────────────────────────────────────────
          "obsidian.desktop"
          "org.gnome.TextEditor.desktop"
          "affine.desktop"

          # ────────────────────────────────────────────────────────────────────
          # creative
          # ────────────────────────────────────────────────────────────────────
          "claude-desktop.desktop"
          "blender.desktop"
          "gimp.desktop"
          "org.inkscape.Inkscape.desktop"
          "org.kde.krita.desktop"
          "Penpot.desktop"
          "com.obsproject.Studio.desktop"

          # ────────────────────────────────────────────────────────────────────
          # ...
          # ────────────────────────────────────────────────────────────────────
          "org.gnome.Nautilus.desktop"
          "megasync.desktop"
          "org.gnome.SystemMonitor.desktop"

          # ────────────────────────────────────────────────────────────────────
          #  DROPPED:
          # ────────────────────────────────────────────────────────────────────
          #
          # ────────────────────────────────────────────────────────────────────
          # PRODUCTIVITY
          # ────────────────────────────────────────────────────────────────────
          # "Logseq.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # LIBREOFFICE
          # ────────────────────────────────────────────────────────────────────
          # "writer.desktop"
          # "calc.desktop"
          # "impress.desktop"
          # "draw.desktop"
          # "base.desktop"
          # "math.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # PDF & DOCS
          # ────────────────────────────────────────────────────────────────────
          # "org.pwmt.zathura.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # EDITORS & IDEs
          # ────────────────────────────────────────────────────────────────────
          # "vim.desktop"
          # "nvim.desktop"
          # "arduino-ide.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # CREATIVITY
          # ────────────────────────────────────────────────────────────────────
          # "audacity.desktop"
          # "org.kde.kdenlive.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # GAMING
          # ────────────────────────────────────────────────────────────────────
          # "steam.desktop"
          # "wine.desktop"
          # "winetricks.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # MUSIC
          # ────────────────────────────────────────────────────────────────────
          # "spotify.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # SECURITY & PRIVACY
          # ────────────────────────────────────────────────────────────────────
          # "org.keepassxc.KeePassXC.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # SYSTEM CONFIGURATION
          # ────────────────────────────────────────────────────────────────────
          # "com.mattjakeman.ExtensionManager.desktop"
          # "ca.desrt.dconf-editor.desktop"
          # "kvantummanager.desktop"
          #  "org.gnome.Settings.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # PROTON APPS
          # ────────────────────────────────────────────────────────────────────
          # "proton-mail.desktop"
          # "proton-pass.desktop"
          # "proton.vpn.app.gtk.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # NIXOS MANUAL
          # ────────────────────────────────────────────────────────────────────
          # "nixos-manual.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # DIAGRAMMING & VISUALIZATION
          # ────────────────────────────────────────────────────────────────────
          # "staruml.desktop"
          # "drawio.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # MEDIA PLAYERS
          # ────────────────────────────────────────────────────────────────────
          #"vlc.desktop"
          #"com.github.rafostar.Clapper.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # VIRTUALIZATION & CONTAINERS
          # ────────────────────────────────────────────────────────────────────
          # "winboat.desktop"
          # "virt-manager.desktop"
          # "podman-desktop.desktop"
          # "com.github.marhkb.Pods.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # NETWORKING & MONITORING
          # ────────────────────────────────────────────────────────────────────
          # "org.wireshark.Wireshark.desktop"
          #
          # ────────────────────────────────────────────────────────────────────
          # DATABASE MANAGEMENT SYSTEMS APPS
          # ────────────────────────────────────────────────────────────────────
          # "redisinsight.desktop"
          # "dbgate.desktop"
          # "sqlitebrowser.desktop"
          # "mongodb-compass.desktop"
          # ────────────────────────────────────────────────────────────────────
        ];
      };

      # ────────────────────────────────────────────────────────────────────────
      # Nautilus
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
      };

      "org/gnome/nautilus/compression" = {
        default-compression-format = "tar.xz";
      };

      # ────────────────────────────────────────────────────────────────────────
      # App Grid Folders
      # ────────────────────────────────────────────────────────────────────────
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "System"
          "Utilities"
        ];
      };

      "org/gnome/desktop/app-folders/folders/System" = {
        name = "X-GNOME-Shell-System.directory";
        translate = true;
        apps = [
          "nm-connection-editor.desktop"
          "org.gnome.baobab.desktop"
          "org.gnome.DiskUtility.desktop"
          "org.gnome.SystemMonitor.desktop"
          "org.gnome.tweaks.desktop"
        ];
      };

      "org/gnome/desktop/app-folders/folders/Utilities" = {
        name = "X-GNOME-Shell-Utilities.directory";
        translate = true;
        apps = [
          "org.gnome.Evince.desktop"
          "org.gnome.font-viewer.desktop"
          "org.gnome.Loupe.desktop"
          "org.gnome.Logs.desktop"
        ];
      };

    };
  };
}
