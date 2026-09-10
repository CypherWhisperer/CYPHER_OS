# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/communication/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
}:
let
  cfg = config.cypher-os.pkgs.communication;
in
{
  imports = [
    ./options.nix
    ./discord.nix
    ./karere.nix
    ./signal.nix
    ./telegram.nix
  ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.communication.enable = lib.mkDefault (cypherOsProfile == "desktop");

    cypher-os.pkgs.communication.signal.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.communication.karere.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.communication.discord.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.communication.telegram.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.communication.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.signal.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.communication.signal.enable requires cypher-os.pkgs.communication.enable.
        '';
      }
      {
        assertion = cfg.karere.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.communication.karere.enable requires cypher-os.pkgs.communication.enable.
        '';
      }
      {
        assertion = cfg.discord.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.communication.discord.enable requires cypher-os.pkgs.communication.enable.
        '';
      }
      {
        assertion = cfg.telegram.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.communication.telegram.enable requires cypher-os.pkgs.communication.enable.
        '';
      }
    ];
  };
}
