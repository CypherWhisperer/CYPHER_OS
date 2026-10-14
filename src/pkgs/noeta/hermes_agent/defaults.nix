# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hermes_agent/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [
    ./options.nix
    ../options.nix
  ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.noeta.hermes.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.noeta.hermes.gateway.enable = lib.mkDefault cfg.hermes.enable;
    cypher-os.pkgs.noeta.hermes.gui.enable = lib.mkDefault (
      cfg.hermes.enable && cypherOsProfile == "desktop"
      );

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.hermes.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.noeta.hermes.enable requires
          cypher-os.pkgs.noeta.enable.
        '';
      }

      {
        assertion = cfg.hermes.gateway.enable -> cfg.hermes.enable;
        message = ''
          cypher-os.pkgs.noeta.hermes.gateway.enable requires
          cypher-os.pkgs.noeta.hermes.enable.
        '';
      }

      {
        assertion = cfg.hermes.gui.enable -> cfg.hermes.enable;
        message = ''
          cypher-os.pkgs.noeta.hermes.gui.enable requires
          cypher-os.pkgs.noeta.hermes.enable.
        '';
      }

      {
        assertion = cfg.hermes.gui.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.noeta.hermes.gui.enable requires
          cypher-os.profile.active == "desktop".
        '';
      }
    ];
  };
}
