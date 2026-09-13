# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/firefox.nix
# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
#   - Firefox installation via programs.firefox (Home Manager module)
#
#   - Profile "default" with full settings, extensions, and chrome CSS
#
#   - Catppuccin theming via catppuccin/nix
#
#   - Vertical tabs via native Firefox sidebar + Tree Style Tab extension
#     + userChrome.css to hide the legacy horizontal tab bar
#
#   - Arkenfox-influenced privacy hardening via programs.firefox settings
#     (NOTE: full arkenfox-nixos module integration is DEFERRED — see below)
#
# ──────────────────────────────────────────────────────────────────────────────
# ── CATPPUCCIN INTEGRATION:
# ──────────────────────────────────────────────────────────────────────────────
#   catppuccin/nix propagates Firefox Color theme to every profile declared
#   under programs.firefox.profiles when catppuccin.firefox.profiles is set.
#
#   With catppuccin.autoEnable = true this happens automatically.
#   The module injects the theme as an extension and sets the Firefox Color
#   preferences. You do NOT need to manually declare the theme extension.
#   Ref: https://nix.catppuccin.com/options/main/home/catppuccin.firefox/
#
# ──────────────────────────────────────────────────────────────────────────────
# ── ARKENFOX:
# ──────────────────────────────────────────────────────────────────────────────
#   Full arkenfox-nixos module (github:dwarfmaster/arkenfox-nixos) integration
#   is DEFERRED. The module generates a typed Home Manager overlay over
#   Arkenfox's user.js, section by section, with the NixOS merge algorithm.
#
#   It requires a flake input and a per-section review pass before enabling.
#   The settings below are manually curated from Arkenfox's recommendations
#   and cover the most impactful privacy/security prefs without the module.
#
#   When ready to graduate:
#    1. Add `arkenfox-nixos.url = "github:dwarfmaster/arkenfox-nixos";` to flake
#    2. Import the HM module in flake's home-manager config
#    3. Set `programs.firefox.profiles.default.arkenfox.enable = true;`
#    4. Enable sections one by one after reviewing each setting
#
# ──────────────────────────────────────────────────────────────────────────────
# ── EXTENSIONS:
# ──────────────────────────────────────────────────────────────────────────────
# Extensions are managed via pkgs.nur.repos.rycee.firefox-addons — the
# standard NUR overlay for declarative Firefox extensions.
#
# NUR setup required in flake.nix:
#   inputs.nur.url = "github:nix-community/NUR";
# And in nixpkgs overlays:
#   nixpkgs.overlays = [ inputs.nur.overlays.default ];
#
# EXTENSIONS NOT IN NUR (must be installed manually or via policy)
#   - Proton Pass  → install manually; no NUR package as of 2025-06
#   - Proton VPN   → install manually; extension is Chromium-first
#   - ColorZilla   → install manually; no NUR package
#   - Workona      → install manually; no NUR package
#   - MetaMask     → CAUTION: active impersonation campaign on AMO (2025-07)
#                    Always verify the extension ID matches the official one:
#                    {1ee72822-5f6f-4a2c-b184-4e0e6c0ba9f6} (@metamask.io)
#                    PENDING manual install; use official metamask.io link only.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── VERTICAL TABS:
# ──────────────────────────────────────────────────────────────────────────────
#   Strategy: Firefox's native sidebar (sidebar.verticalTabs = true) combined
#   with Tree Style Tab extension for tree grouping, and userChrome.css to
#   collapse the legacy horizontal tab bar. The native sidebar reached stable
#   in Firefox 131+ and does not require about:config flags in 131+.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── VERIFYING SETUP:
# ──────────────────────────────────────────────────────────────────────────────
#   After switch:
#     ls -la ~/.mozilla/firefox/default/chrome/userChrome.css  # must be a file
#     firefox about:config → toolkit.legacyUserProfileCustomizations.stylesheets = true
#     Extensions appear in about:addons under "Managed" or "From file"
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

  config = lib.mkIf (cfg.enable && cfg.firefox.enable) {
    programs.firefox = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # ── Privacy/Security Policies (system-level, cannot be overridden
      # by user) ─ These apply machine-wide and survive profile resets.
      # ────────────────────────────────────────────────────────────────────────
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true; # no Mozilla sync — you're self-sovereign
        DisableFormHistory = true;
        DisableFeedbackCommands = true;
        DisableSetDesktopBackground = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";

        # ──────────────────────────────────────────────────────────────────────
        # Force-disable crash reporting and metrics endpoints
        # ──────────────────────────────────────────────────────────────────────
        DisableCrashReporter = true;

        # ──────────────────────────────────────────────────────────────────────
        # Search engine: point to a privacy-respecting default
        # DuckDuckGo is the safest declarable default without a custom search.json
        SearchBar = "unified"; # search + address bar combined
        # ──────────────────────────────────────────────────────────────────────
      };

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        # ────────────────────────────────────────────────────────────────────
        # ── about:config Preferences ───────────────────────────────────────────
        # Order follows Arkenfox section numbering for traceability.
        # See: https://github.com/arkenfox/user.js/wiki
        # ────────────────────────────────────────────────────────────────────
        settings = {

          # §0100 — Startup
          "browser.startup.page" = 0; # blank page on startup
          "browser.startup.homepage" = "about:blank";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.default.sites" = "";

          # ────────────────────────────────────────────────────────────────────
          # §0200 — Geolocation
          # ────────────────────────────────────────────────────────────────────
          "geo.provider.network.url" = "";
          "geo.enabled" = false;
          "browser.region.network.url" = "";
          "browser.region.update.enabled" = false;

          # ────────────────────────────────────────────────────────────────────
          # §0300 — Language / Locale
          # NOTE: Setting intl.accept_languages to "en-US, en" improves
          # fingerprint uniformity but may break region-specific sites. Keeping
          # it loose here.
          # ────────────────────────────────────────────────────────────────────
          "intl.accept_languages" = "en-US, en";
          "javascript.use_us_english_locale" = true;

          # ────────────────────────────────────────────────────────────────────
          # §0400 — Telemetry (belt-and-suspenders on top of policies)
          # ────────────────────────────────────────────────────────────────────
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "app.shield.optoutstudies.enabled" = false;
          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";
          "breakpad.reportURL" = "";
          "browser.tabs.crashReporting.sendReport" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.coverage.opt-out" = true;
          "toolkit.coverage.endpoint.base" = "";

          # ────────────────────────────────────────────────────────────────────
          # §0500 — Geolocation / Safe Browsing (network call tradeoffs)
          # Safe Browsing sends URL hashes to Google. Disable if your threat
          # model prioritises privacy over phishing protection; keep enabled if
          # you visit unknown links regularly. Commented out = keep Firefox
          # default (enabled).
          # ────────────────────────────────────────────────────────────────────
          #"browser.safebrowsing.malware.enabled"   = false;
          #"browser.safebrowsing.phishing.enabled"  = false;
          #"browser.safebrowsing.downloads.enabled" = false;
          #"browser.safebrowsing.blockedURIs.enabled" = false;

          # ────────────────────────────────────────────────────────────────────
          # §0600 — Network
          # ────────────────────────────────────────────────────────────────────
          "network.prefetch-next" = false;
          "network.dns.disablePrefetch" = true;
          "network.dns.disablePrefetchFromHTTPS" = true;
          "network.predictor.enabled" = false;
          "network.http.speculative-parallel-limit" = 0;
          "browser.places.speculativeConnect.enabled" = false;
          "network.proxy.socks_remote_dns" = true; # DNS over SOCKS when proxied

          # ────────────────────────────────────────────────────────────────────
          # DNS-over-HTTPS via Quad9 (privacy-respecting, no logging)
          # Mode 3 = DoH only (strict); mode 2 = DoH with fallback to system DNS
          # ────────────────────────────────────────────────────────────────────
          "network.trr.mode" = 2; # 2 = fallback; raise to 3 when you trust VPN
          "network.trr.uri" = "https://dns.quad9.net/dns-query";
          "network.trr.bootstrapAddress" = "9.9.9.9";

          # ────────────────────────────────────────────────────────────────────
          # §0700 — DNS / Proxy / Socks
          # ────────────────────────────────────────────────────────────────────
          "network.gio.supported-protocols" = ""; # attack surface reduction

          # ────────────────────────────────────────────────────────────────────
          # §0900 — Disk / Avoidance
          # Disabling disk cache reduces persistence but hurts performance.
          # Uncomment to go Arkenfox-level paranoid.
          # "browser.cache.disk.enable"           = false;
          # "browser.privatebrowsing.forceMediaMemoryCache" = true;
          # ────────────────────────────────────────────────────────────────────
          "browser.sessionhistory.max_total_viewers" = 4;

          # ────────────────────────────────────────────────────────────────────
          # 1000 — Headers / Referer
          # ────────────────────────────────────────────────────────────────────
          "network.http.referer.XOriginPolicy" = 2; # only send to same eTLD+1
          "network.http.referer.XOriginTrimmingPolicy" = 2; # strip to scheme+host+port

          # ────────────────────────────────────────────────────────────────────
          # §1200 — HTTPS / SSL
          # ────────────────────────────────────────────────────────────────────
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_error_page_user_suggestions" = true;
          "security.ssl.require_safe_negotiation" = true;
          "security.tls.version.min" = 3; # TLS 1.2 minimum (3 = TLS 1.2)
          "security.tls.version.max" = 4; # TLS 1.3 max
          # ────────────────────────────────────────────────────────────────────
          # OCSP — disabling hardens against timing attacks but breaks
          # revocation checking
          # ────────────────────────────────────────────────────────────────────
          #"security.OCSP.enabled" = 0;
          # ────────────────────────────────────────────────────────────────────
          "security.cert_pinning.enforcement_level" = 2;
          "security.remote_settings.crlite_filters.enabled" = true;
          "security.pki.crlite_mode" = 2;

          # ────────────────────────────────────────────────────────────────────
          # §1400 — Fonts
          # ────────────────────────────────────────────────────────────────────
          # Set to 0 if you want Arkenfox-level fingerprint reduction
          # ────────────────────────────────────────────────────────────────────
          "browser.display.use_document_fonts" = 1; # 0 = block all web fonts; 1 = allow

          # ────────────────────────────────────────────────────────────────────
          # 1600 — Headers
          # ────────────────────────────────────────────────────────────────────
          "permissions.default.geo" = 2; # deny geolocation requests
          "permissions.default.camera" = 2;
          "permissions.default.microphone" = 2;
          "permissions.default.desktop-notification" = 2;
          "permissions.default.xr" = 2; # deny WebXR/VR

          # ────────────────────────────────────────────────────────────────────
          # §1700 — WebRTC
          # WebRTC leaks your real IP even behind a VPN. Disable entirely if you
          # don't do video calls in Firefox; re-enable per-site via exceptions.
          # ────────────────────────────────────────────────────────────────────
          "media.peerconnection.enabled" = false;
          "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
          "media.peerconnection.ice.default_address_only" = true;

          # ────────────────────────────────────────────────────────────────────
          # §1800 — Plugins
          # ────────────────────────────────────────────────────────────────────
          "plugin.default.state" = 0;
          "plugin.scan.plid.all" = false;

          # ────────────────────────────────────────────────────────────────────
          # §2000 — History
          # ────────────────────────────────────────────────────────────────────
          "places.history.enabled" = true; # keep history (personal preference)
          "browser.formfill.enable" = false;
          "signon.autofillForms" = false; # use Proton Pass instead
          "signon.formlessCapture.enabled" = false;
          "signon.privateBrowsingCapture.enabled" = false;
          "network.auth.subresource-http-auth-allow" = 1;

          # ────────────────────────────────────────────────────────────────────
          # §2200 — Window / Tab behaviour
          # ────────────────────────────────────────────────────────────────────
          "browser.link.open_newwindow" = 3; # open in new tab, not window
          "browser.link.open_newwindow.restriction" = 0;

          # ────────────────────────────────────────────────────────────────────
          # §2300 — Shutdown
          # Clear on shutdown: set these to true if you want ephemeral sessions
          # ────────────────────────────────────────────────────────────────────
          "privacy.sanitize.sanitizeOnShutdown" = false;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "privacy.clearOnShutdown.formdata" = false;
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.sessions" = false;

          # ────────────────────────────────────────────────────────────────────
          # §2400 — Fingerprinting
          # SET TO FALSE: Due to web content theming; i.e
          # Configuring a dark theme is disabled because ResistFingerprinting is
          # enabled.
          # This means Firefox will force web content to display in a light
          # theme.
          # ────────────────────────────────────────────────────────────────────
          "privacy.resistFingerprinting" = false;
          "privacy.fingerprintingProtection" = true;
          # ────────────────────────────────────────────────────────────────────
          # NOTE: resistFingerprinting sets window size to a uniform 1000x900
          # bucket.This can feel odd. You can relax it:
          # ────────────────────────────────────────────────────────────────────
          #"privacy.resistFingerprinting.letterboxing" = true;  # adds grey bars instead
          "privacy.resistFingerprinting.randomDataOnCanvasExtract" = true;

          # ────────────────────────────────────────────────────────────────────
          # §2600 — DOM
          # ────────────────────────────────────────────────────────────────────
          "dom.disable_window_move_resize" = true;
          "dom.disable_beforeunload" = true;
          "dom.disable_window_flip" = true;
          "dom.disable_open_during_load" = true;
          "dom.popup_maximum" = 4;

          # ────────────────────────────────────────────────────────────────────
          # §2700 — ETP (Enhanced Tracking Protection)
          # ────────────────────────────────────────────────────────────────────
          "browser.contentblocking.category" = "strict";
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;
          "privacy.trackingprotection.emailtracking.enabled" = true;

          # ────────────────────────────────────────────────────────────────────
          # §2800 — Shutdown (storage isolation)
          # ────────────────────────────────────────────────────────────────────
          "privacy.partition.network_state.ocsp_cache" = true;

          # ────────────────────────────────────────────────────────────────────
          # §4500 — Optional opsec
          # ────────────────────────────────────────────────────────────────────
          "browser.urlbar.speculativeConnect.enabled" = false;
          "browser.urlbar.dnsResolveSingleWordsAfterSearch" = 0;

          # ────────────────────────────────────────────────────────────────────
          # ── Vertical Tabs (native Firefox sidebar) ───────────────────────────
          # Firefox 131+ ships native vertical tabs via the sidebar revamp.
          # sidebar.verticalTabs was promoted to stable settings in 131+.
          # ────────────────────────────────────────────────────────────────────
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "hide-sidebar"; # ← collapsed by default, expands on hover
          #"sidebar.main.tools" = "aichat,syncedtabs,history"; # optional: what appears in sidebar

          # ────────────────────────────────────────────────────────────────────
          # Required for userChrome.css to load (hides horizontal tab bar)
          # ────────────────────────────────────────────────────────────────────
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # ────────────────────────────────────────────────────────────────────
          # ── UX.
          # ────────────────────────────────────────────────────────────────────
          "browser.tabs.tabMinWidth" = 76;
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1; # compact density
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.tabs.closeWindowWithLastTab" = false;
          "browser.aboutConfig.showWarning" = false;
          "accessibility.force_disabled" = 1; # minor attack surface reduction
        };

        # ──────────────────────────────────────────────────────────────────────
        # ── userChrome.css — Hide legacy horizontal tab bar.
        # ──────────────────────────────────────────────────────────────────────
        # Required when using Tree Style Tab or native vertical tabs.
        # The @-moz-document wrapper is mandatory from Firefox 69+.
        # ──────────────────────────────────────────────────────────────────────
        userChrome = ''
          @-moz-document url(chrome://browser/content/browser.xhtml) {
            /*
             * Hide the legacy horizontal tab bar.
             * Tree Style Tab (or native sidebar verticalTabs) replaces it.
             * To restore: delete this file and toggle sidebar.verticalTabs = false.
             */
            #TabsToolbar {
              visibility: collapse !important;
            }

            /*
             * Hide the Tree Style Tab sidebar header (redundant chrome).
             * The sidebar command ID must match the extension's internal ID.
             */
            #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"]
            #sidebar-header {
              visibility: collapse !important;
            }

            /*
             * Compact the navigation bar height — pairs well with compact density.
             */
            #nav-bar {
              padding-top: 2px !important;
              padding-bottom: 2px !important;
            }
          }
        '';

        # ──────────────────────────────────────────────────────────────────────
        # ── Extensions (NUR-managed, declarative).
        # ──────────────────────────────────────────────────────────────────────
        # NUR setup: inputs.nur.url = "github:nix-community/NUR"
        #            nixpkgs.overlays = [ inputs.nur.overlays.default ];
        # Search available addons: https://nur.nix-community.org/repos/rycee/
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
          # ────────────────────────────────────────────────────────────────────
          # ── Privacy & Security (MUST-HAVE).
          # ────────────────────────────────────────────────────────────────────
          ublock-origin # content blocker; best-in-class, maintained
          privacy-badger # heuristic tracker blocker (EFF); complements uBO

          # ────────────────────────────────────────────────────────────────────
          # serves common CDN resources locally; prevents CDN tracking
          # ────────────────────────────────────────────────────────────────────
          decentraleyes

          # ────────────────────────────────────────────────────────────────────
          # NOTE: LocalCDN is a more maintained fork of Decentraleyes — consider
          # switching: PENDING: localcdn is not yet in rycee NUR; install
          # manually from AMO if desired
          # ────────────────────────────────────────────────────────────────────
          clearurls # strips tracking parameters from URLs (e.g. ?utm_source=)

          # ────────────────────────────────────────────────────────────────────
          # ── Password Management.
          # ────────────────────────────────────────────────────────────────────
          # Proton Pass — NOT in NUR as of 2025-06; install manually from:
          # https://addons.mozilla.org/en-US/firefox/addon/proton-pass/
          # PENDING: proton-pass

          # ────────────────────────────────────────────────────────────────────
          # ── Tabs & Navigation.
          # ────────────────────────────────────────────────────────────────────
          # Note: pairs with sidebar.verticalTabs = true and the userChrome.css
          # above
          # ────────────────────────────────────────────────────────────────────
          tree-style-tab # hierarchical vertical tabs with tree grouping

          # ────────────────────────────────────────────────────────────────────
          # ── Appearance.
          # ────────────────────────────────────────────────────────────────────
          # Catppuccin theme is injected by catppuccin/nix automatically.
          # DO NOT add a Firefox Color extension manually — it will conflict.
          #
          # Dark Reader: makes sites dark using generated CSS. Useful when
          # catppuccin theme doesn't cover site content (it only covers
          # browser chrome). error: undefined variable 'dark-reader'
          # ────────────────────────────────────────────────────────────────────
          #dark-reader # dark mode for all web content

          # ────────────────────────────────────────────────────────────────────
          # ── Developer Tools.
          # ────────────────────────────────────────────────────────────────────
          react-devtools # React component inspector

          # ────────────────────────────────────────────────────────────────────
          # ── Utility.
          # ────────────────────────────────────────────────────────────────────
          # ColorZilla — NOT in NUR; install manually:
          # https://addons.mozilla.org/en-US/firefox/addon/colorzilla/
          # PENDING: colorzilla

          # ────────────────────────────────────────────────────────────────────
          # Workona — closed-source tab workspace manager; NOT in NUR.
          # Privacy note: Workona syncs tab state to their servers.
          # Alternatives:
          # - Simple Tab Groups (open-source, local): in NUR as
          #   `simple-tab-groups`
          #
          # - Tab Session Manager (NUR: tab-session-manager)
          #
          # EXCLUDED: workona — closed-source, cloud-sync; violates
          # privacy/ sovereignty posture
          #
          # Enable simple-tab-groups instead:
          # ────────────────────────────────────────────────────────────────────
          simple-tab-groups # open-source local tab workspace grouping
          tab-session-manager # save/restore session snapshots locally

          # ────────────────────────────────────────────────────────────────────
          # Web Vitals / Performance
          # (no declarative package for this; lightweight enough to skip)
          # ────────────────────────────────────────────────────────────────────

          # ────────────────────────────────────────────────────────────────────
          # ── Crypto.
          # ────────────────────────────────────────────────────────────────────
          # MetaMask — CAUTION: active large-scale impersonation campaign on
          # AMO (Jul 2025).
          # Only install from: https://metamask.io/download/ → direct AMO link.
          # Verify extension ID: {1ee72822-5f6f-4a2c-b184-4e0e6c0ba9f6}
          # NOT in NUR (would require pinning a specific XPI hash).
          # PENDING: metamask — manual install only; verify ID before installing
          # ────────────────────────────────────────────────────────────────────
        ];

        # ──────────────────────────────────────────────────────────────────────
        # ── uBlock Origin declarative filter list configuration.
        # ──────────────────────────────────────────────────────────────────────
        # Home Manager 24.11+ supports extensions.settings for per-extension
        # prefs.
        # ──────────────────────────────────────────────────────────────────────
        extensions.settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters" # uBO's own filter list
              "ublock-badware" # known malware domains
              "ublock-privacy" # privacy filters
              "ublock-unbreak" # fix breakage from above lists
              "ublock-quick-fixes" # rapid-response fixes
              "easylist" # core ad list
              "easyprivacy" # tracking parameters / beacons
              "adguard-generic" # AdGuard base list
              "adguard-mobile" # mobile-specific (belt+suspenders)
              "adguard-annoyances" # ← add: blocks YT overlays, consent dialogs
              "adguard-social" # ← add: social widgets
              "ublock-annoyances" # ← add: uBO's own annoyances list
              "urlhaus-1" # abuse.ch malware URL database
            ];
          };
        };
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    #  Catppuccin Firefox Integration.
    # ──────────────────────────────────────────────────────────────────────────
    # catppuccin/nix automatically propagates the theme to profiles declared
    # under programs.firefox.profiles when catppuccin.firefox.profiles is set.
    # With catppuccin.autoEnable = true (in theming.nix), this is already active.
    #
    # The below is explicit for clarity and to pin flavor/accent per-profile
    # in case theming.nix ever changes the global defaults.
    # ──────────────────────────────────────────────────────────────────────────
    catppuccin.librewolf.profiles.default = {
      enable = true;
      flavor = catppuccinFlavor;
      accent = catppuccinAccent;
    };
  };
}
