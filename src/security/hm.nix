# ──────────────────────────────────────────────────────────────────────────────
# src/security/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.security;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.keepassxc.enable) {
      home.packages = with pkgs; [ keepassxc ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.security.enable = lib.mkDefault (cypherOsProfile == "desktop");
      cypher-os.security.keepassxc.enable = lib.mkDefault cfg.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.security.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        {
          assertion = cfg.keepassxc.enable -> cfg.enable;
          message = ''
            cypher-os.security.keepassxc.enable requires cypher-os.security.enable.
          '';
        }
      ];
    }
  ];
}
