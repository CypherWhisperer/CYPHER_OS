# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hm.nix
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
    ./claude_code.nix
    ./codex.nix
    ./hermes.nix
    ./open_code.nix
    ./t3_code.nix
  ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.noeta.enable = lib.mkDefault true;

      cypher-os.pkgs.noeta.openCode.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.claudeCode.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.codex.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.hermes.enable = lib.mkDefault cfg.enable;

      cypher-os.pkgs.noeta.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.pkgs.noeta.gui.t3Code.enable = lib.mkDefault cfg.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.openCode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.openCode.enable requires cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.claudeCode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.claudeCode.enable requires cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.codex.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.codex.enable requires cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.hermes.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.hermes.enable requires cypher-os.pkgs.noeta.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.enable requires cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.gui.enable -> (cypherOsProfile == "desktop");
          message = ''
            cypher-os.pkgs.noeta.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }
        {
          assertion = cfg.gui.t3Code.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.t3Code.enable requires cypher-os.pkgs.noeta.gui.enable.
          '';
        }
      ];
    }
  ];
}
