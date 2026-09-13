# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/mail/thunderbird.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.mail;
  bridgeCfg = config.cypher-os.pkgs.mail.protonBridge;
  catppuccinAccent = config.cypher-os.theme.accent;
  catppuccinFlavor = config.cypher-os.theme.flavor;
  inherit (lib) mkIf mkMerge;
in
{
  imports = [ ./options.nix ];

  config = mkIf (cfg.enable && cfg.thunderbird.enable) {

    # ──────────────────────────────────────────────────────────────────────────
    # Guard: protonSupport requires Bridge to also be enabled so Thunderbird
    # never starts in a state where it expects a local IMAP/SMTP proxy that
    # isn't running.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = !cfg.thunderbird.protonSupport || bridgeCfg.enable;
        message = ''
          cypher-os.pkgs.mail.thunderbird.protonSupport = true requires
          cypher-os.pkgs.mail.protonBridge.enable = true.
        '';
      }
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # Catppuccin theme via catppuccin/nix.
    # ──────────────────────────────────────────────────────────────────────────
    # The XPI is placed in2 the profile's extensions directory by catppuccin/nix
    # at derivation time — no manual extension installation required.
    #
    # flavor always inherits from the global catppuccin.flavor
    # (mocha by default). accent falls back to the global catppuccin.accent
    # unless overridden per-instance.
    # ──────────────────────────────────────────────────────────────────────────
    catppuccin.thunderbird = {
      enable = true;
      flavor = catppuccinFlavor;
      accent = catppuccinAccent;
    };

    programs.thunderbird = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # Global preferences — applied to every profile via user.js.
      # ────────────────────────────────────────────────────────────────────────
      settings = {
        # ──────────────────────────────────────────────────────────────────────
        # Disable telemetry and health reporting.
        # ──────────────────────────────────────────────────────────────────────
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;

        # ──────────────────────────────────────────────────────────────────────
        # Required for userChrome.css to take effect (structural tweaks beyond
        # the catppuccin theme, e.g. compact headers, hidden toolbar elements).
        # ──────────────────────────────────────────────────────────────────────
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # ──────────────────────────────────────────────────────────────────────
        # Compact UI density (0=compact, 1=normal, 2=touch).
        # ──────────────────────────────────────────────────────────────────────
        "mail.uidensity" = 0;

        # ──────────────────────────────────────────────────────────────────────
        # Suppress the first-run rights/welcome nag.
        # ──────────────────────────────────────────────────────────────────────
        "mail.rights.version" = 1;
      };

      profiles.${cfg.thunderbird.profile} = {
        isDefault = true;

        settings = mkMerge [
          # ────────────────────────────────────────────────────────────────────
          # Base profile preferences.
          # ────────────────────────────────────────────────────────────────────
          {
            # ──────────────────────────────────────────────────────────────────
            # Plain text composition by default — avoids HTML leaking metadata.
            # ──────────────────────────────────────────────────────────────────
            "mail.compose.default_to_paragraph" = false;
            "mail.html_compose" = false;

            # ──────────────────────────────────────────────────────────────────
            # Open messages in a tab rather than a new window.
            # ──────────────────────────────────────────────────────────────────
            "mail.openMessageBehavior" = 0;

            # ──────────────────────────────────────────────────────────────────
            # Enable threaded view by default.
            # ──────────────────────────────────────────────────────────────────
            "mail.thread.sort_order" = true;

            # ──────────────────────────────────────────────────────────────────
            # ISO-adjacent date format.
            # ──────────────────────────────────────────────────────────────────
            "mail.date_format" = 5;

            # ──────────────────────────────────────────────────────────────────
            # Block remote content (tracking pixels) by default.
            # ──────────────────────────────────────────────────────────────────
            "mailnews.message_display.disable_remote_image" = true;
          }

          # ────────────────────────────────────────────────────────────────────
          # Proton Bridge connection preferences.
          # ────────────────────────────────────────────────────────────────────
          # These tell Thunderbird to accept plain-password auth to localhost,
          # which is required for the Bridge-generated app-password flow.
          #
          # Account wiring (server address, username, port) is deferred to the
          # one-time manual setup after Bridge's interactive login ceremony.
          # ────────────────────────────────────────────────────────────────────
          (mkIf cfg.thunderbird.protonSupport {
            "mail.server.default.authMethod" = 4; # normal password
            "mail.smtpserver.default.authMethod" = 4;
          })
        ];
      };
    };
  };
}
