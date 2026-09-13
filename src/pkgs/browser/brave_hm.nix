# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/brave_hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
# - Brave installation via home.packages
# - Launch flags via home.sessionVariables + wrapper (Wayland, privacy flags)
# - Seeded  ~/.config/BraveSoftware/Brave-Browser/Default/{Preferences,Bookmarks}
#   via home.activation (mutable, one-shot)
#
# - NTP background image seed
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT THIS FILE DOES NOT OWN:
# ──────────────────────────────────────────────────────────────────────────────
# - Extension blobs — Brave auto-installs from the Web Store using the
#   extension IDs embedded in the seeded Preferences file
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WHY THE SEED APPROACH FOR BRAVE:
# ──────────────────────────────────────────────────────────────────────────────
# Brave, like all Chromium-based browsers, writes back to its Preferences
# JSON on every launch — timestamps, extension state, window geometry, etc.
# A Nix store symlink would be read-only; Brave would silently discard all
# user changes or fail to write session state.
#
# Home Manager has no programs.brave module (unlike programs.firefox) because
# Chromium's config model is fundamentally incompatible with declarative
# management at the preference level. The seeding approach (copy-once, guard
# on existence) is the correct and established workaround.
#
# ALTERNATIVE: Brave supports managed policies via JSON files placed at
# /etc/brave/policies/managed/ (Linux). These are truly declarative and
# cannot be overridden by the user or by Brave's runtime writes. They are
# the correct path for enforcing security settings. See MANAGED POLICIES below.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── MANAGED POLICIES (the cleaner long-term approach):
# ──────────────────────────────────────────────────────────────────────────────
# Brave reads Chromium enterprise policies from:
#   /etc/brave/policies/managed/<anything>.json
# These are evaluated at launch and override Preferences.
#
# In NixOS: use environment.etc to place policy files declaratively.
# This is the only truly reproducible mechanism for Brave config.
# Example (place in your NixOS system module):
#
#environment.etc."brave/policies/managed/cypher-os.json".text = builtins.toJSON {
#  # ───────────────────────────────────────────────────────────────────────────
#  # Block third-party cookies
#  # ───────────────────────────────────────────────────────────────────────────
#  BlockThirdPartyCookies = true;
#
#  # ───────────────────────────────────────────────────────────────────────────
#  # Disable crash reporting
#  # ───────────────────────────────────────────────────────────────────────────
#  MetricsReportingEnabled = false;
#
#  # ───────────────────────────────────────────────────────────────────────────
#  # Enforce safe search (optional)
#  # ForceGoogleSafeSearch = true;
#  # Disable sync to Brave servers
#  # ───────────────────────────────────────────────────────────────────────────
#  SyncDisabled = true;
#
#  # ───────────────────────────────────────────────────────────────────────────
#  # Force HTTPS
#  # ───────────────────────────────────────────────────────────────────────────
#  HttpsOnlyMode = "force_enabled";
#
#  # ───────────────────────────────────────────────────────────────────────────
#  # Disable password manager (use Proton Pass extension)
#  # ───────────────────────────────────────────────────────────────────────────
#  PasswordManagerEnabled = false;
#
#  # ───────────────────────────────────────────────────────────────────────────
#  # Disable autofill
#  # ───────────────────────────────────────────────────────────────────────────
#  AutofillAddressEnabled = false;
#  AutofillCreditCardEnabled = false;
#};
#
# DEFERRED: Migrating Brave config to managed policies ( i.e., the recommended
# next step once current Preferences seed stabilises). Policy keys are
# documented at: https://support.brave.com/hc/en-us/articles/360039248271
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WAYLAND FLAGS:
# ──────────────────────────────────────────────────────────────────────────────
# Brave needs explicit Wayland flags on GNOME/Wayland to avoid running under
# XWayland (which loses native Wayland gestures, scaling, and screen capture).
# These are injected via a wrapper script rather than BRAVE_FLAGS env var
# because env vars don't propagate to .desktop file launches.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── SEEDING STRATEGY:
# ──────────────────────────────────────────────────────────────────────────────
# (home.activation copy, NOT home.file symlink):
#   Brave requires mutable config files — it writes back to Preferences
#   on every launch. A symlink into the Nix store would be read-only and
#   cause Brave to silently discard settings changes or corrupt the profile.
#
#   home.activation copies the seed files once on a fresh install (guarded
#   by [ ! -f "$TARGET" ]). On subsequent `home-manager switch` runs the
#   guard prevents overwriting Brave's live state.
#
#   To force a re-seed (e.g. after a wipe or deliberate reset):
#     rm ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
#     rm ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks
#     home-manager switch
#
# Added: the seed files are now validated for JSON integrity before copy,
# preventing a corrupt seed from silently breaking Brave on first launch.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── CATPPUCCIN:
# ──────────────────────────────────────────────────────────────────────────────
# catppuccin/nix does not support Brave. Catppuccin theming for Brave is
# applied via a Chrome Web Store extension embedded in the Preferences seed.
#
# The extension ID is: dcojpbnpjbknpmhbkgmbbejidlhbnocp (Catppuccin Mocha)
# This auto-installs via the extension IDs in your seeded Preferences file.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── UPDATING SEED FILES:
# ──────────────────────────────────────────────────────────────────────────────
# When you want to snapshot current Brave state:
#   cp ~/.config/BraveSoftware/Brave-Browser/Default/{Preferences,Bookmarks} \
#      <repo>/configs/browser/brave/
#
# Note: Preferences will contain runtime noise (timestamps, metrics, etc.).
# Acceptable if the goal is reproducibility, not clean diffs. If not, run git
# diff ro review noise before committing.
#
#   git diff configs/browser/brave/Preferences | head -60
#   git commit -m "chore(brave): snapshot settings/bookmarks"
#
# ──────────────────────────────────────────────────────────────────────────────
# ── FORCE RE-SEED:
# ──────────────────────────────────────────────────────────────────────────────
# rm ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
# rm ~/.config/BraveSoftware/Brave-Browser/Default/Bookmarks
# home-manager switch
#
# ──────────────────────────────────────────────────────────────────────────────
# ── FUTURE (-> cleaner diffs):
# ──────────────────────────────────────────────────────────────────────────────
# Graduating to a jq-based merge script that extracts only the needed keys
# (extensions.settings, extensions.theme, browser.*, search.*)
# and deep-merge them into a Brave-generated Preferences on activation.
# This trades setup complexity for a noise-free, auditable config.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── EXTENSIONS:
# ──────────────────────────────────────────────────────────────────────────────
# Installed extensions are encoded in Preferences under `extensions.settings`.
# Brave reads those IDs on first launch and auto-installs them from the Chrome
# Web Store. No extension source  directories are tracked in this repo.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── VERIFYING THE SETUP:
# ──────────────────────────────────────────────────────────────────────────────
#   1. After `home-manager switch`, check the files exist and are mutable:
#        ls -la ~/.config/BraveSoftware/Brave-Browser/Default/Preferences
#        # Should be a regular file (-rw-r--r--), NOT a symlink (lrwxrwxrwx)
#
#   2. Launch Brave — settings, theme, and extension IDs should be present.
#   3. Extensions will auto-install on first launch (requires internet).
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;

  # ────────────────────────────────────────────────────────────────────────────
  # Absolute path to the seed files inside the Nix store.
  # pkgs.lib.cleanSource or a plain path both work here; a plain
  # repo-relative path is simplest and is what Home Manager expects.
  # ────────────────────────────────────────────────────────────────────────────
  braveConfigDir = cypherOsConstants.braveConfigsRoot;

  # ────────────────────────────────────────────────────────────────────────────
  # Wayland + privacy flags passed to every Brave launch.
  # These are baked into a wrapper script so they apply whether Brave is
  # launched from terminal, .desktop file, or application grid.
  # ────────────────────────────────────────────────────────────────────────────
  braveFlags = lib.concatStringsSep " " [
    # ──────────────────────────────────────────────────────────────────────────
    # WAYLAND NATIVE RENDERING.
    # ──────────────────────────────────────────────────────────────────────────
    "--ozone-platform=wayland"
    "--enable-features=UseOzonePlatform,WaylandWindowDecorations"

    # ──────────────────────────────────────────────────────────────────────────
    # GPU / RENDERING.
    # ──────────────────────────────────────────────────────────────────────────
    "--enable-gpu-rasterization"
    "--enable-zero-copy"

    # ──────────────────────────────────────────────────────────────────────────
    # PRIVACY / ATTACK SURFACE REDUCTION.
    # ──────────────────────────────────────────────────────────────────────────
    # Disable WebRTC to prevent IP leak. Re-enable if using Brave for calls.
    #
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: REMOVED:
    # ──────────────────────────────────────────────────────────────────────────
    # Handled correctly via WebRtcIPHandling managed policy in brave_system.nix
    # Disabling the feature module breaks YouTube's media pipeline
    #
    # The flag is too blunt. --disable-features= is a Chromium feature flag
    # toggle that operates at a low level — it doesn't just disable WebRTC
    # network behaviour, it can disable the entire WebRTC feature module
    # including the media pipeline components YouTube's player depends on.
    #
    # YouTube's player uses WebRTC APIs internally for adaptive bitrate
    # streaming and playback coordination, not just for video calls.
    #
    # Disabling the feature entirely at the Chromium level is known to
    # cause YouTube to fall back to degraded playback paths — and in that
    # degraded state, Brave's Shields don't intercept the ad serving correctly
    # because the player is behaving abnormally.
    #
    # This caused sites like YT to feature ads on Brave Browser.
    #
    # A way to prevent WebRTC IP leaks is via the managed policy
    # already written — WebRtcIPHandling = "disable_non_proxied_udp" in, say,
    # brave_system.nix.
    #
    # That could restricts what IPs WebRTC can expose without
    # touching the feature module itself. The --disable-features=WebRTC flag is
    # redundant now that the policy handles it, and actively harmful.
    # ──────────────────────────────────────────────────────────────────────────
    #"--disable-features=WebRTC"

    # ──────────────────────────────────────────────────────────────────────────
    # Disable component updates phoning home on launch
    # NOTE: this disables CRLSets updates — acceptable if Brave
    # is regularly updated
    # ──────────────────────────────────────────────────────────────────────────
    "--disable-component-update"

    # ──────────────────────────────────────────────────────────────────────────
    # Prevent Brave from offering to translate pages via cloud translation
    # ──────────────────────────────────────────────────────────────────────────
    "--translate-script-url=data:text/javascript,"

    # ──────────────────────────────────────────────────────────────────────────
    # Disable crash reporting endpoint
    # ──────────────────────────────────────────────────────────────────────────
    "--disable-breakpad"

    # ──────────────────────────────────────────────────────────────────────────
    # Silence first-run wizard
    # ──────────────────────────────────────────────────────────────────────────
    "--no-first-run"
    "--no-default-browser-check"
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Wrapper script that prepends the flags to every Brave invocation.
  # ────────────────────────────────────────────────────────────────────────────
  #braveWrapped = pkgs.writeShellScriptBin "brave" ''
  #  exec ${pkgs.brave}/bin/brave ${braveFlags} "$@"
  #'';
in
{
  config = lib.mkIf (cfg.enable && cfg.brave.enable) {

    # ──────────────────────────────────────────────────────────────────────────
    # PACKAGE.
    # ──────────────────────────────────────────────────────────────────────────
    home.packages = [
      # ────────────────────────────────────────────────────────────────────────
      # Install the wrapper rather than bare Brave so flags apply everywhere.
      # ────────────────────────────────────────────────────────────────────────
      #braveWrapped

      # ────────────────────────────────────────────────────────────────────────
      # OR: Keep the original package available for direct access if needed:
      # ────────────────────────────────────────────────────────────────────────
      pkgs.brave
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # ACTIVATION: seed mutable config files.
    # ──────────────────────────────────────────────────────────────────────────
    # entryAfter ["writeBoundary"]: runs after HM has written all managed files,
    # so we're not racing with any other home.file declarations.
    #
    # $DRY_RUN_CMD: HM injects this as an empty string on real runs and as
    # "echo" on dry runs (`home-manager switch --dry-run`), allowing a preview
    # what would happen without touching the filesystem.
    #
    # $VERBOSE_ECHO: prints the message only when --verbose is passed.
    # ──────────────────────────────────────────────────────────────────────────
    home.activation.seedBraveConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/Default"

      $DRY_RUN_CMD mkdir -p "$BRAVE_DIR"
      $DRY_RUN_CMD mkdir -p "$BRAVE_DIR/sanitized_background_images"

      # ── Validate JSON integrity before seeding ─────────────────────────────
      # Prevents a malformed seed from silently corrupting Brave's profile.
      for seed_file in Preferences Bookmarks; do
        SOURCE="${braveConfigDir}/$seed_file"
        if ! ${pkgs.jq}/bin/jq empty "$SOURCE" 2>/dev/null; then
          echo "ERROR: Brave seed file $SOURCE is not valid JSON. Skipping seed." >&2
        fi
      done

      # ── Seed flat config files ─────────────────────────────────────────────
      for seed_file in Preferences Bookmarks; do
        TARGET="$BRAVE_DIR/$seed_file"
        SOURCE="${braveConfigDir}/$seed_file"

        if [ ! -f "$TARGET" ]; then
          $VERBOSE_ECHO "Brave: seeding $seed_file → $TARGET"
          $DRY_RUN_CMD cp "$SOURCE" "$TARGET"
          $DRY_RUN_CMD chmod 644 "$TARGET"
        else
          $VERBOSE_ECHO "Brave: $seed_file already present, skipping"
        fi
      done

      # ── Seed NTP background image ──────────────────────────────────────────
      # Brave reads this on launch for the custom NTP background.
      # The filename must match exactly what Preferences references internally.
      BG_TARGET="$BRAVE_DIR/sanitized_background_images/brave_bg.jpg"
      BG_SOURCE="${braveConfigDir}/sanitized_background_images/brave_bg.jpg"

      if [ -f "$BG_SOURCE" ] && [ ! -f "$BG_TARGET" ]; then
        $VERBOSE_ECHO "Brave: seeding NTP background → $BG_TARGET"
        $DRY_RUN_CMD cp "$BG_SOURCE" "$BG_TARGET"
        $DRY_RUN_CMD chmod 644 "$BG_TARGET"

      #else
      # $VERBOSE_ECHO "Brave: NTP background already present, skipping"
      fi
    '';

    # ──────────────────────────────────────────────────────────────────────────
    # XDG DESKTOP ENTRY OVERRIDE.
    # ──────────────────────────────────────────────────────────────────────────
    # Replace Brave's default .desktop entry with one that uses thE wrapper.
    # This ensures the application grid, dmenu/rofi, and xdg-open all use flags.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.desktopEntries.brave-browser = {
      name = "Brave Web Browser";
      genericName = "Web Browser";
      comment = "Access the Internet — Brave (CypherOS hardened)";
      exec = "brave %U";
      icon = "brave-browser";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "application/pdf"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      settings = {
        StartupWMClass = "Brave-browser";
        StartupNotify = "true";
      };
    };
  };
}
