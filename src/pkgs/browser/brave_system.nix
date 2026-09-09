# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/brave_system.nix
# ──────────────────────────────────────────────────────────────────────────────
# NixOS SYSTEM module for Brave managed policies.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WHY THIS EXISTS:
# ──────────────────────────────────────────────────────────────────────────────
# Brave (Chromium-based) writes back to:
#   ~/.config/BraveSoftware/.../Preferences
# on every launch. Any preference set there can be overwritten by Brave itself
# at runtime.
#
# Managed policies, placed at /etc/brave/policies/managed/, are evaluated at
# launch BEFORE Preferences and CANNOT be overridden by the browser or by user
# action. They are the only truly declarative, durable mechanism for enforcing
# Brave configuration.
#
# This is the NixOS equivalent of a corporate MDM policy pushed to a fleet,
# except the "fleet" is your own machine and you are the admin.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── VERIFYING POLICIES ARE ACTIVE:
# ──────────────────────────────────────────────────────────────────────────────
# After nixos-rebuild switch, launch Brave and navigate to:
#   brave://policy
#
# Every key declared below should appear with Status = "OK" and
# Source = "Machine". If a key shows "Error" check the JSON is valid.
#
# Also check: brave://settings — managed settings will show a
# building/organisation icon and "Managed by your organisation".
#
# ──────────────────────────────────────────────────────────────────────────────
# ── POLICY KEY SOURCES:
# ──────────────────────────────────────────────────────────────────────────────
# Brave-specific keys: https://support.brave.com/hc/en-us/articles/360039248271
# Chromium inherited keys: https://chromeenterprise.google/policies/
# Verified working keys sourced from:
#   - Brave's own GitHub issue tracker (brave/brave-browser)
#   - Gentoo wiki Brave entry (confirmed Linux policy JSON)
#   - Brave community forum confirmed working configs
#
# ──────────────────────────────────────────────────────────────────────────────
# ── UBLOCK ORIGIN NOTE:
# ──────────────────────────────────────────────────────────────────────────────
# As of mid-2025, Google removed MV2 extensions from the Chrome Web Store.
# Brave hosts uBlock Origin on its own MV2 backend
# (brave://settings/extensions/v2) but has NOT published a policy-accessible
# update URL for force-install.
#
# ExtensionInstallForcelist with the old CWS URL no longer works.
#
# Current declarative strategy for uBlock in Brave:
#   1. Embed uBlock Origin's extension ID in seeded Preferences file
#      (brave-hm.nix activation script). Brave auto-installs from its MV2 cache.
#
#   2. This system module enforces all other privacy/security settings.
#   3. uBlock's filter lists are configured via the seeded Preferences.
#
# PENDING: Monitor https://github.com/brave/brave-browser/issues for a
# documented MV2 force-install policy URL from Brave's own update backend.
# When available, add: "ExtensionInstallForcelist": ["<id>;<brave-update-url>"]
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;

  # ────────────────────────────────────────────────────────────────────────────
  # Policy object — single source of truth.
  # Written to /etc/brave/policies/managed/cypher-os.json via environment.etc.
  # ────────────────────────────────────────────────────────────────────────────
  bravePolicy = {
    # ──────────────────────────────────────────────────────────────────────────
    # §1 — BRAVE FEATURE KILL-SWITCHES
    # ──────────────────────────────────────────────────────────────────────────
    # Remove surface area. Every disabled feature is one less thing that can
    # phone home, get exploited, or clutter the UI.
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # AI / Leo — sends queries to Brave's servers. Hard no.
    # ──────────────────────────────────────────────────────────────────────────
    BraveAIChatEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Rewards — opt-in ad system that requires BAT wallet and Brave server comms
    # ──────────────────────────────────────────────────────────────────────────
    BraveRewardsDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Wallet — Web3 wallet. Eenable only if a primary wallet strategy is needed
    # ──────────────────────────────────────────────────────────────────────────
    BraveWalletDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # VPN — Brave's commercial VPN product.
    # ──────────────────────────────────────────────────────────────────────────
    BraveVPNDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # News / Brave Today — fetches headlines via Brave's proxy. Unnecessary.
    # ──────────────────────────────────────────────────────────────────────────
    BraveNewsDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Talk — Brave's Jitsi-based video calling. Not used; disable.
    # ──────────────────────────────────────────────────────────────────────────
    BraveTalkDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Speedreader — article reformatter that makes network requests.
    # ──────────────────────────────────────────────────────────────────────────
    BraveSpeedreaderEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Wayback Machine integration — sends URLs to the Internet Archive.
    # Useful tool but shouldn't be integrated at the browser level
    # without consent.
    # ──────────────────────────────────────────────────────────────────────────
    BraveWaybackMachineEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Playlist — video/audio download queue feature. Disable.
    # ──────────────────────────────────────────────────────────────────────────
    BravePlaylistEnabled = false;
    # ──────────────────────────────────────────────────────────────────────────

    # IPFS — peer-to-peer content addressing. Disabling removes the local IPFS
    # node that Brave can spin up. Reduces background network activity.
    # NOTE: If you're actively using IPFS/Web3, set this to true.
    # ──────────────────────────────────────────────────────────────────────────
    IPFSEnabled = false;
    # ──────────────────────────────────────────────────────────────────────────

    # Tor integration — Brave ships a bundled Tor binary for "Private Window
    # with Tor". This is INSECURE compared to Tor Browser proper:
    #   - No circuit isolation between tabs
    #   - Lacks Tor Browser's fingerprint hardening
    #   - Brave's Tor implementation has had leaks (2021)
    # CypherOS supports tor - both the daemon and the browser.
    # ──────────────────────────────────────────────────────────────────────────
    TorDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # §2 — TELEMETRY & REPORTING
    # Every telemetry endpoint is a vector for data collection and a network
    # request that can be observed by your ISP or a network adversary.
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # P3A — "Privacy-Preserving Product Analytics". Even privacy-preserving
    # analytics is analytics. Disable.
    # ──────────────────────────────────────────────────────────────────────────
    BraveP3AEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Stats ping — daily usage ping to Brave's servers.
    # ──────────────────────────────────────────────────────────────────────────
    BraveStatsPingEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Web Discovery Project — opt-in search query sharing with Brave Search.
    # ──────────────────────────────────────────────────────────────────────────
    BraveWebDiscoveryEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Chrome metrics reporting — Chromium's own UMA telemetry.
    # ──────────────────────────────────────────────────────────────────────────
    MetricsReportingEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Crash reporting
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: No direct policy key exists for Brave crash reports on Linux.
    # `--disable-breakpad` flag in the HM wrapper (./brave_hm.nix) handles this.
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # Safe Browsing — sends URL hashes to Google's servers to check for malware.
    # TRADEOFF: Disabling removes phishing/malware protection. Acceptable here
    # because uBlock Origin + Brave Shields cover the same threat space without
    # Google involvement. If you feel exposed, set to true.
    #
    # EXCLUDED: too aggressive for general use
    # ──────────────────────────────────────────────────────────────────────────
    # SafeBrowsingEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # URL keylogging — Chromium can send partial URLs typed in the address bar
    # to the default search engine for suggestions. Disable.
    # 0 = disable all suggestions that require network requests
    # ──────────────────────────────────────────────────────────────────────────
    SearchSuggestEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # §3 — PRIVACY & DATA MINIMISATION
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # Password manager. Brave's password manager syncs
    # to Brave Sync servers if enabled. Disable entirely.
    # To Me: Use Proton Pass
    # ──────────────────────────────────────────────────────────────────────────
    PasswordManagerEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Autofill — form data stored and potentially synced.
    # To Me: Use Proton Pass instead.
    # ──────────────────────────────────────────────────────────────────────────
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Sync — Brave Sync sends data to Brave's servers (encrypted, but still).
    # To me: You are self-sovereign. Disable.
    # ──────────────────────────────────────────────────────────────────────────
    SyncDisabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Sign-in — Brave account sign-in prompt. Disable.
    # ──────────────────────────────────────────────────────────────────────────
    BrowserSignin = 0; # 0 = disable sign-in

    # ──────────────────────────────────────────────────────────────────────────
    # Third-party cookies — block globally.
    # ──────────────────────────────────────────────────────────────────────────
    BlockThirdPartyCookies = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Global Privacy Control — sends a GPC signal to sites requesting they
    # not sell/share your data. Sites that honour it must comply (CCPA etc).
    # Brave supports GPC natively via policy.
    # ──────────────────────────────────────────────────────────────────────────
    GlobalPrivacyControlEnabled = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Translate — Brave's page translation sends content to a translation server
    # ──────────────────────────────────────────────────────────────────────────
    TranslateEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # §4 — DNS OVER HTTPS
    # Policy-level DoH. Applies regardless of what the user sets in
    # brave://settings.
    # Using Quad9 for consistency with Firefox and LibreWolf configuration.
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # "secure" = DoH only, no fallback to plaintext DNS
    #            (equivalent to Firefox trr.mode=3)
    #
    # "automatic" = DoH with fallback (equivalent to Firefox trr.mode=2)
    #
    # "automatic" used here so Brave doesn't break in captive portal situations
    # (airports, hotels) where Quad9 may be unreachable without plaintext
    # DNS first.
    # ──────────────────────────────────────────────────────────────────────────
    DnsOverHttpsMode = "automatic";
    DnsOverHttpsTemplates = "https://dns.quad9.net/dns-query";

    # ──────────────────────────────────────────────────────────────────────────
    # §5 — SECURITY HARDENING
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # HTTPS-only mode — force HTTPS everywhere.
    # "force_enabled" = HTTPS only, no HTTP fallback (strictest)
    # "enabled" = prompt user before loading HTTP page (balanced)
    # ──────────────────────────────────────────────────────────────────────────
    HttpsOnlyMode = "force_enabled";

    # ──────────────────────────────────────────────────────────────────────────
    # QUIC protocol — Google's UDP-based transport. Disable: it bypasses
    # standard TCP/IP analysis tools, complicates VPN routing, and has had
    # privacy leaks in Chromium implementations.
    # ──────────────────────────────────────────────────────────────────────────
    QuicAllowed = false;

    # ──────────────────────────────────────────────────────────────────────────
    # WebRTC leak prevention — force only media IPs (no local IP exposure).
    # "disable_non_proxied_udp" = most restrictive; may break some calls
    # "default_public_interface_only" = balanced; hides local IPs
    # ──────────────────────────────────────────────────────────────────────────
    WebRtcIPHandling = "disable_non_proxied_udp";

    # ──────────────────────────────────────────────────────────────────────────
    # Background mode — Brave running in background after all windows closed.
    # Disable: reduces attack surface and stops Brave from making network
    # requests when you think it's closed.
    # ──────────────────────────────────────────────────────────────────────────
    BackgroundModeEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # Default browser check prompt — suppress.
    # ──────────────────────────────────────────────────────────────────────────
    DefaultBrowserSettingEnabled = false;

    # ──────────────────────────────────────────────────────────────────────────
    # §6 — SHIELDS (Brave-specific ad/tracker blocking)
    # These are Brave-native policies not present in standard Chromium.
    # Verified from Brave's issue tracker and community forum as working keys.
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: BraveShieldsAdBlockMode and BraveShieldsTrackerMode are NOT
    # documented in Brave's official policy list as of 2025-06.
    #
    # Shields level enforcement via policy is PENDING upstream documentation.
    # The correct current approach is:
    #  1. Set shields to Aggressive in the seeded Preferences file.
    #  2. Snapshot the Preferences file with shields set correctly
    #  3. The seed guard in brave_hm.nix activation ensures this survives
    #     reinstall
    #
    # DEFERRED: When Brave publishes official policy keys for Shields level,
    # add them here. Track: https://github.com/brave/brave-browser/issues/22029
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # §7 — EXTENSION MANAGEMENT
    # ──────────────────────────────────────────────────────────────────────────
    # Block all extensions except those explicitly allowlisted.
    # This prevents extensions being installed that aren't in the seed
    # Preferences.
    # The wildcard "*" blocks all; allowlisted IDs override the block.
    #
    # uBlock Origin (MV2, Brave-hosted):  cjpalhdlnbpafiamejdnhcphjbkeiagm
    # MetaMask:                           nkbihfbeogaeaoehlefnkodbefgpgknn
    # Proton Pass:                        ghmbeldphafepmbegfdlkpapadhbakde
    # ColorZilla:                         bhlhnicpbhignbdhedgjmacdmmjfjbnm
    #
    # To find an extension ID: install it, go to brave://extensions, enable
    # Developer Mode, the ID appears under the extension name.
    # ──────────────────────────────────────────────────────────────────────────
    ExtensionSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # Default: block all extensions not listed below
      # ────────────────────────────────────────────────────────────────────────
      "*" = {
        installation_mode = "blocked";
      };
      # ────────────────────────────────────────────────────────────────────────
      # uBlock Origin — primary ad/tracker blocker
      # ────────────────────────────────────────────────────────────────────────
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # MetaMask — Web3 wallet
      # ────────────────────────────────────────────────────────────────────────
      "nkbihfbeogaeaoehlefnkodbefgpgknn" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # Proton Pass — password manager
      # ────────────────────────────────────────────────────────────────────────
      "ghmbeldphafepmbegfdlkpapadhbakde" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # ColorZilla — color picker dev tool
      # ────────────────────────────────────────────────────────────────────────
      "bhlhnicpbhignbdhedgjmacdmmjfjbnm" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # React Developer Tools
      # ────────────────────────────────────────────────────────────────────────
      "fmkadmapgofadopljbjfkapdkoienihi" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # Dark Reader (optional in Brave alongside Shields)
      # ────────────────────────────────────────────────────────────────────────
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" = {
        installation_mode = "allowed";
      };
      # ────────────────────────────────────────────────────────────────────────
      # Catppuccin Mocha theme extension (Chrome Web Store, cosmetic only)
      # ID: dcojpbnpjbknpmhbkgmbbejidlhbnocp
      # ────────────────────────────────────────────────────────────────────────
      "dcojpbnpjbknpmhbkgmbbejidlhbnocp" = {
        installation_mode = "allowed";
      };
    };
  };

in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.brave.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # Deploy policy file.
    # ──────────────────────────────────────────────────────────────────────────
    # environment.etc writes to /etc/ at nixos-rebuild switch time.
    # The file is owned by root, read by Brave at every launch. Changes take
    # effect on next Brave launch (no restart required for most keys).
    # ──────────────────────────────────────────────────────────────────────────
    environment.etc."brave/policies/managed/cypher-os.json" = {
      text = builtins.toJSON bravePolicy;
      mode = "0644";
      user = "root";
      group = "root";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Ensure policy directory exists
    # ──────────────────────────────────────────────────────────────────────────
    # environment.etc handles file creation but not intermediate directories
    # if they don't already exist. This activation script creates them.
    # On NixOS, /etc/brave/ and subdirectories won't exist until created.
    # ──────────────────────────────────────────────────────────────────────────
    system.activationScripts.bravePoliciesDir = lib.stringAfter [ "etc" ] ''
      mkdir -p /etc/brave/policies/managed
      mkdir -p /etc/brave/policies/recommended
      chmod 755 /etc/brave/policies/managed
      chmod 755 /etc/brave/policies/recommended
    '';
  };
}
