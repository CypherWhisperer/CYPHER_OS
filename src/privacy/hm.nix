# ──────────────────────────────────────────────────────────────────────────────
# src/privacy/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, pkgs, config, cypherOsProfile, ... }:

let
  cfg = config.cypher-os.privacy;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # Packages eligible for both Server and Desktop Profile
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.tor.enable) {
      home.packages = with pkgs; [ tor ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    # Each package is its own leaf under gui.*, so future additions don't
    # collapse into one shared switch, unless that's explicitly desired
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.gui.enable && cfg.gui.megasync.enable) {
      home.packages = with pkgs; [ megasync ];
    })

    (lib.mkIf (cfg.enable && cfg.gui.enable && cfg.gui.protonSuite.enable) {
      home.packages = with pkgs; [
        proton-vpn
        proton-pass
        protonmail-desktop
        #protonmail-bridge-gui
        #protonmail-bridge
      ];
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
      cypher-os.privacy.enable = lib.mkDefault true;
      cypher-os.privacy.tor.enable = lib.mkDefault cfg.enable;
      cypher-os.privacy.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.privacy.gui.megasync.enable = lib.mkDefault cfg.gui.enable;
      cypher-os.privacy.gui.protonSuite.enable = lib.mkDefault cfg.gui.enable;
    }

    {
      assertions = [
        {
          assertion = cfg.tor.enable -> cfg.enable;
          message = ''
            cypher-os.privacy.tor.enable requires cypher-os.privacy.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.privacy.gui.enable requires cypher-os.privacy.enable.
          '';
        }

        {
          # ────────────────────────────────────────────────────────────────────
          # Stated once here — every leaf under gui.* inherits this via
          # the leaf-implies-gui.enable assertion below, transitively.
          # ────────────────────────────────────────────────────────────────────
          assertion = cfg.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.privacy.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        {
          assertion = cfg.gui.megasync.enable -> cfg.gui.enable;
          message = ''
            cypher-os.privacy.gui.megasync.enable requires cypher-os.privacy.gui.enable.
          '';
        }

        {
          assertion = cfg.gui.protonSuite.enable -> cfg.gui.enable;
          message = ''
            cypher-os.privacy.gui.protonSuite.enable requires cypher-os.privacy.gui.enable.
          '';
        }
      ];
    }
  ];
}
