# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/mail/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.mail;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.mail.enable = lib.mkDefault (cypherOsProfile == "desktop");
    cypher-os.pkgs.mail.thunderbird.enable = lib.mkDefault cfg.enable;
    # cypher-os.pkgs.mail.protonBridge.enable = lib.mkDefault cfg.enable; # overriden
    cypher-os.pkgs.mail.protonBridge.enable = lib.mkDefault false;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.mail.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.protonBridge.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.mail.protonBridge.enable requires cypher-os.pkgs.mail.enable.
        '';
      }

      {
        assertion = cfg.thunderbird.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.mail.thunderbird.enable requires cypher-os.pkgs.mail.enable.
        '';
      }
    ];
  };
}
