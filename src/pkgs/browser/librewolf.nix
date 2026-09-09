# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/librewolf.nix
# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
# - LibreWolf installation via programs.librewolf (Home Manager module)
# - Profile "default" with privacy settings, extensions, and chrome CSS
# - Catppuccin theming via catppuccin/nix (catppuccin.librewolf.*)
# - Vertical tabs (same strategy as Firefox)
#
# ──────────────────────────────────────────────────────────────────────────────
# ── LIBREWOLF vs FIREFOX HARDENING:
# ──────────────────────────────────────────────────────────────────────────────
# LibreWolf ships Arkenfox-influenced defaults OUT OF THE BOX:
#   - All telemetry disabled by default
#   - privacy.resistFingerprinting = true by default
#   - WebGL disabled by default
#   - Clear-on-shutdown enabled by default
#   - No pocket, no sponsored tiles, no Mozilla accounts
#
# The settings block here is therefore mostly RELAXATIONS of LibreWolf's
# aggressive defaults to make it usable as a daily driver. You are
# explicitly trading off some privacy for usability. Each relaxation is
# commented with the reason.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── CATPPUCCIN:
# ──────────────────────────────────────────────────────────────────────────────
# catppuccin/nix supports LibreWolf natively via catppuccin.librewolf.*.
# Same propagation mechanism as Firefox: theme injected via Firefox Color.
# Ref: https://nix.catppuccin.com/options/25.05/home/catppuccin.librewolf/
#
# ──────────────────────────────────────────────────────────────────────────────
# ── EXTENSIONS IN LIBREWOLF:
# ──────────────────────────────────────────────────────────────────────────────
# programs.librewolf.profiles.<n>.extensions uses the same NUR rycee
# firefox-addons source as Firefox. LibreWolf shares the Gecko extension API.
#
# KNOWN ISSUE (HM 25.05): LibreWolf does not follow symlink-to-symlink chains
# for extensions directory. If extensions fail to load after switch, verify:
#   ls -la ~/.librewolf/<profile>/extensions/
#
# If symlinks point to the Nix store correctly but extensions still don't load,
# this is the known bug: github.com/nix-community/home-manager/issues/7948
#
# Workaround: install affected extensions manually until upstream fix lands.
# ──────────────────────────────────────────────────────────────────────────────
# ── VERIFYING SETUP:
# ──────────────────────────────────────────────────────────────────────────────
# After `home-manager switch`:
#   ls -la ~/.librewolf/<profile>/chrome/userChrome.css
#   librewolf about:config → toolkit.legacyUserProfileCustomizations.stylesheets
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;
  catppuccinFlavor = config.cypher-os.theme.flavor;
  catppuccinAccent = config.cypher-os.theme.accent;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.librewolf.enable) {

    programs.librewolf = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # Global settings (apply to all profiles)
      # ────────────────────────────────────────────────────────────────────────
      # These relax LibreWolf's most aggressive defaults.
      # Everything not listed here retains LibreWolf's hardened defaults.
      # ────────────────────────────────────────────────────────────────────────
      settings = {
        # ──────────────────────────────────────────────────────────────────────
        # WebGL: LibreWolf disables by default. Re-enable for web apps that
        # require it (Figma, Penpot browser, some map renderers).
        # TRADEOFF: WebGL exposes GPU fingerprinting surface.
        # ──────────────────────────────────────────────────────────────────────
        "webgl.disabled" = false;

        # ──────────────────────────────────────────────────────────────────────
        # resistFingerprinting: LibreWolf enables by default. Keeping it ON.
        # NOTE: This sets the OS reported to Windows to reduce fingerprint
        # variance. Disable only if OS spoofing causes UNTOLERABLE breakage.
        #
        # SET TO FALSE: Due to web content theming; i.e
        # Configuring a dark theme is disabled because ResistFingerprinting is
        # enabled. This means LibreWolf will force web content to display in
        # a light theme.
        # ──────────────────────────────────────────────────────────────────────
        "privacy.resistFingerprinting" = false;

        # ──────────────────────────────────────────────────────────────────────
        # History: LibreWolf clears on shutdown by default. Relax for usability.
        # ──────────────────────────────────────────────────────────────────────
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.sanitize.sanitizeOnShutdown" = false;

        # ──────────────────────────────────────────────────────────────────────
        # Cookies: LibreWolf sets lifetimePolicy = 2 (expire on session end).
        # Set to 0 = accept cookies normally (honor server expiry).
        # ──────────────────────────────────────────────────────────────────────
        "network.cookie.lifetimePolicy" = 0;

        # ──────────────────────────────────────────────────────────────────────
        # HTTPS-only mode: keep on (LibreWolf default is off; enforce it)
        # ──────────────────────────────────────────────────────────────────────
        "dom.security.https_only_mode" = true;

        # ──────────────────────────────────────────────────────────────────────
        # DNS-over-HTTPS (same Quad9 config as Firefox)
        # ──────────────────────────────────────────────────────────────────────
        "network.trr.mode" = 2;
        "network.trr.uri" = "https://dns.quad9.net/dns-query";
        "network.trr.bootstrapAddress" = "9.9.9.9";

        # ──────────────────────────────────────────────────────────────────────
        # Proton Pass: LibreWolf's default disables form autofill. Keep disabled
        # since Proton Pass extension handles password autofill.
        # ──────────────────────────────────────────────────────────────────────
        "signon.autofillForms" = false;
        "signon.formlessCapture.enabled" = false;

        # ──────────────────────────────────────────────────────────────────────
        # Vertical tabs (same as Firefox module)
        # ──────────────────────────────────────────────────────────────────────
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        # ──────────────────────────────────────────────────────────────────────
        # collapsed by default, expands on hover
        # ──────────────────────────────────────────────────────────────────────
        "sidebar.visibility" = "hide-sidebar";

        # ──────────────────────────────────────────────────────────────────────
        # optional: what appears in sidebar
        # ──────────────────────────────────────────────────────────────────────
        #"sidebar.main.tools" = "aichat,syncedtabs,history";

        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # ──────────────────────────────────────────────────────────────────────
        # UX quality-of-life
        # ──────────────────────────────────────────────────────────────────────
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.aboutConfig.showWarning" = false;
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.link.open_newwindow" = 3;
      };

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        # ──────────────────────────────────────────────────────────────────────
        # userChrome.css
        # ──────────────────────────────────────────────────────────────────────
        userChrome = ''
          @-moz-document url(chrome://browser/content/browser.xhtml) {
            /* Hide legacy horizontal tab bar — vertical sidebar replaces it */
            #TabsToolbar {
              visibility: collapse !important;
            }

            /* Hide Tree Style Tab sidebar header chrome */
            #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"]
            #sidebar-header {
              visibility: collapse !important;
            }

            /* Compact nav bar */
            #nav-bar {
              padding-top: 2px !important;
              padding-bottom: 2px !important;
            }
          }
        '';

        # ──────────────────────────────────────────────────────────────────────
        # ── Extensions.
        # ──────────────────────────────────────────────────────────────────────
        # See NOTE in header re: HM 25.05 symlink bug for LibreWolf.
        #
        # What force = true means: it tells Home Manager you are intentionally
        # taking declarative ownership of all extension settings for this
        # profile, and you accept that anything not declared here will be
        # absent. It's a safeguard against accidentally wiping extension config
        # you set manually — once you declare it, you own it entirely.
        # Correct posture for CypherOS.
        # ──────────────────────────────────────────────────────────────────────
        extensions.force = true;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          privacy-badger
          decentraleyes
          clearurls
          tree-style-tab
          react-devtools
          simple-tab-groups
          tab-session-manager
          # ────────────────────────────────────────────────────────────────────
          #dark-reader # error: undefined variable 'dark-reader'
          # ────────────────────────────────────────────────────────────────────
        ];

        extensions.settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
              "easylist"
              "easyprivacy"
              "adguard-generic"
              "adguard-annoyances"
              "adguard-social"
              "ublock-annoyances"
              "urlhaus-1"
            ];
          };
        };
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── Catppuccin LibreWolf Integration.
    # ──────────────────────────────────────────────────────────────────────────
    catppuccin.librewolf.profiles.default = {
      enable = true;
      flavor = catppuccinFlavor;
      accent = catppuccinAccent;
    };
  };
}
