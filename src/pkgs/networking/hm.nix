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
    
    (lib.mkIf (cfg.enable && cfg.tshark.enable) {
      home.packages = with pkgs; [ tshark ];
    })

    (lib.mkIf (cfg.enable && cfg.inetutils.enable) {
      home.packages = with pkgs; [ inetutils ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.gui.enable && cfg.gui.wireshark.enable) {
      home.packages = with pkgs; [ wireshark ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.networking.enable = lib.mkDefault true;
      cypher-os.pkgs.networking.nmap.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.tcpdump.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.gobuster.enable = lib.mkDefault cfg.enable;
      # ────────────────────────────────────────────────────────────────────────
      # > pkgs.buildEnv error: two given paths contain a conflicting subpath:
      # > `/nix/store/[hash]-wireshark-qt-4.6.8/bin/androiddump' and
      # > `/nix/store/[hash]-wireshark-cli-4.6.8/bin/androiddump'
      # > hint: this may be caused by two different versions of the same package
      #   in buildEnv's `paths` parameter
      # > hint: `pkgs.nix-diff` can be used to compare derivations
      # ────────────────────────────────────────────────────────────────────────
      cypher-os.pkgs.networking.tshark.enable = lib.mkDefault false; # overriden
      cypher-os.pkgs.networking.inetutils.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.networking.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.pkgs.networking.gui.wireshark.enable = lib.mkDefault cfg.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
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
          assertion = cfg.tshark.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.tshark.enable requires cypher-os.pkgs.networking.enable.
          '';
        }
        {
          assertion = cfg.inetutils.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.inetutils.enable requires cypher-os.pkgs.networking.enable.
          '';
        }
        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.networking.gui.enable requires cypher-os.pkgs.networking.enable.
          '';
        }

        {
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
