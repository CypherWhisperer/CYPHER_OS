# ──────────────────────────────────────────────────────────────────────────────
# src/security/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, pkgs, config, cypherOsProfile, ... }:

let
  cfg = config.cypher-os.security;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    # Each package is its own leaf under gui.*, so future additions don't
    # collapse into one shared switch, unless that's explicitly desired
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.keepassxc.enable) {
      home.packages = with pkgs; [ keepassxc ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # CONFIGURATION DEFAULTS
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: pick ONE shape for the category's own top-level enable, don't leave
    # both:
    #
    #   Both-profile category:
    #     cypher-os. ... .enable = lib.mkDefault true; # i.e., no profile gating
    #
    #   Desktop-only category:
    #     cypher-os. ... .enable = lib.mkDefault (cypherOsProfile == "desktop");
    #     — pair with the matching assertion below.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.security.enable = lib.mkDefault (cypherOsProfile == "desktop");
      cypher-os.security.keepassxc.enable = lib.mkDefault cfg.enable;
    }

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
