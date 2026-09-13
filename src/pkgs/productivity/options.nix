# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.productivity = {
    enable = lib.mkEnableOption "CypherOS Productivity Applications";

    obs.enable = lib.mkEnableOption "LibreOffice Suite";
    claude.enable = lib.mkEnableOption "Claude Desktop";
    zathura.enable = lib.mkEnableOption "Zathura PDF reader";
    logseq.enable = lib.mkEnableOption "Logseq knowledge base";
    affine.enable = lib.mkEnableOption "AFFiNE knowledge base";
    libreOffice.enable = lib.mkEnableOption "LibreOffice Suite";
    obsidian.enable = lib.mkEnableOption "Obsidian Desktop Productivity App";

    drawio.enable = lib.mkEnableOption "Drawio Software System Design App";
    staruml.enable = lib.mkEnableOption "StarUML Software System Design App";

    anydesk = {
      enable = lib.mkEnableOption "AnyDesk remote desktop client";
    };

    rustdesk = {
      enable = lib.mkEnableOption "RustDesk remote desktop client";

      server = {
        enable = lib.mkEnableOption ''
          self-hosted RustDesk signaling/relay server (hbbs/hbbr) on this host.
          Independent of the client — the client works against the public
          RustDesk relay with this left disabled.
        '';

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open the hbbs/hbbr ports (21115-21119) in the firewall.";
        };

        relayHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "cypher-server.example.tld" ];
          description = ''
            IP(s)/DNS name(s) hbbs advertises to clients as the relay (hbbr)
            location. Required for hbbs to point clients at the right hbbr.
          '';
        };

        signalExtraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra CLI flags passed through to hbbs.";
        };

        relayExtraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra CLI flags passed through to hbbr.";
        };
      };
    };
  };
}
