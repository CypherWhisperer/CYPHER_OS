# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/networking/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, pkgs, config, cypherOsProfile, ... }:

let
  cfg = config.cypher-os.pkgs.networking;
in
{
  imports = [ ./options.nix ];
  config = lib.mkMerge [

    # ──────────────────────────────────────────────────────────────────────────
    # Packages eligible for both Server and Desktop Profile
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.nmap.enable) {
      home.packages = with pkgs; [ nmap ];
    })

    (lib.mkIf (cfg.enable && cfg.tcpdump.enable) {
      home.packages = with pkgs; [ tcpdump ];
    })


    (lib.mkIf (cfg.enable && cfg.gobuster.enable) {
      home.packages = with pkgs; [ gobuster ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    # Each package is its own leaf under gui.*, so future additions don't
    # collapse into one shared switch, unless that's explicitly desired
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.gui.enable && cfg.gui.wireshark.enable) {
      home.packages = with pkgs; [ wireshark ];
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
      cypher-os.pkgs.networking.enable = lib.mkDefault true;
      cypher-os.pkgs.networking.nmap.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.tcpdump.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.gobuster.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.pkgs.networking.gui.wireshark.enable = lib.mkDefault cfg.gui.enable;
    }

    {
      assertions = [
        {
          assertion = cfg.nmap.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.nmap.enable requires cypher-os.pkgs.networking.enable.
          '';
        }

        {
          assertion = cfg.tcpdump.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.tcpdump.enable requires cypher-os.pkgs.networking.enable.
          '';
        }

        {
          assertion = cfg.gobuster.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.gobuster.enable requires cypher-os.pkgs.networking.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.gui.enable requires cypher-os.pkgs.networking.enable.
          '';
        }

        {
          # ────────────────────────────────────────────────────────────────────
          # Stated once here — every leaf under gui.* inherits this via
          # the leaf-implies-gui.enable assertion below, transitively.
          # ────────────────────────────────────────────────────────────────────
          assertion = cfg.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.networking.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        {
          assertion = cfg.gui.wireshark.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.networking.gui.wireshark.enable requires cypher-os.pkgs.networking.gui.enable.
          '';
        }
      ];
    }
  ];
}
