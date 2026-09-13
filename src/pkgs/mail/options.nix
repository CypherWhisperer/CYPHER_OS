# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/mail/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.cypher-os.pkgs.mail = {
    enable = mkEnableOption "CypherOS mail applications";

    thunderbird = {
      enable = mkEnableOption "Thunderbird email client";

      profile = mkOption {
        type = types.str;
        default = "cypher";
        description = "Name of the primary Thunderbird profile.";
      };

      # Null defers to the global catppuccin.accent value.
      catppuccinAccent = mkOption {
        type = types.nullOr (
          types.enum [
            "blue"
            "flamingo"
            "green"
            "lavender"
            "maroon"
            "mauve"
            "peach"
            "pink"
            "red"
            "rosewater"
            "sapphire"
            "sky"
            "teal"
            "yellow"
          ]
        );
        default = null;
        description = ''
          Per-instance accent override for the Thunderbird catppuccin theme.
          When null, inherits catppuccin.accent from the global catppuccin/nix config.
        '';
      };

      protonSupport = mkEnableOption ''
        Proton Mail Bridge integration for Thunderbird.
        Requires cypher-os.pkgs.mail.protonBridge.enable = true.
      '';
    };

    protonBridge = {
      enable = mkEnableOption "Proton Mail Bridge local IMAP/SMTP proxy daemon";

      imapPort = mkOption {
        type = types.port;
        default = 1143;
        description = "Local IMAP port that Bridge will listen on.";
      };

      smtpPort = mkOption {
        type = types.port;
        default = 1025;
        description = "Local SMTP port that Bridge will listen on.";
      };
    };
  };
}
