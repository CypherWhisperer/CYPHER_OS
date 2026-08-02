{
  lib,
  pkgs,
  ...
}:

{
  options.cypher-os.apps.productivity = {
    enable = lib.mkEnableOption "CypherOS Productivity Applications";
    claude.enable = lib.mkEnableOption "Claude Desktop";
    obsidian.enable = lib.mkEnableOption "Obsidian Desktop App";
    penpot.enable = lib.mkEnableOption "Penpot Design App";
    logseq.enable = lib.mkEnableOption "Logseq knowledge base";
    affine.enable = lib.mkEnableOption "AFFiNE knowledge base";
    zathura.enable = lib.mkEnableOption "Zathura PDF reader";
    libreOffice.enable = lib.mkEnableOption "LibreOffice Suite";
    obs.enable = lib.mkEnableOption "LibreOffice Suite";

    d2 = {
      enable = lib.mkEnableOption "D2 diagram scripting language, CLI + shared theming defaults";

      package = lib.mkOption {
        type = lib.types.package;
        # default = config.cypher-os.pkgs.d2 or null; # fall back to nixpkgs (d2-hm.nix)
        default = pkgs.d2;
        description = "The d2 package to install.";
      };

      # ── Shared rendering defaults ────────────────────────────────────────────
      # Consumed by: this module (env vars), obsidian.nix (plugin settings),
      # vscode.nix (extension settings). Single source of truth so all three
      # surfaces render diagrams identically instead of drifting apart.
      layoutEngine = lib.mkOption {
        type = lib.types.enum [
          "dagre"
          "elk"
          "tala"
        ];
        default = "elk";
        description = ''
          Default layout engine. dagre is fastest and bundled; elk handles
          larger/nested architecture diagrams better; tala is a paid binary
          layout engine purpose-built for software architecture (not bundled,
          not used here).
        '';
      };

      themeId = lib.mkOption {
        type = lib.types.int;
        default = 200; # "Dark Mauve" — matches the Catppuccin Mocha Mauve neutral palette
        description = "Light-mode theme ID. Run `d2 themes` for the full catalogue.";
      };

      darkThemeId = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 200;
        description = ''
          Dark-mode theme ID (SVG-only). Leave null to keep diagrams static
          regardless of the viewer's colour-scheme preference.
        '';
      };

      pad = lib.mkOption {
        type = lib.types.int;
        default = 20;
        description = "Padding, in pixels, around the rendered diagram.";
      };

      sketch = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Render diagrams as if hand-drawn.";
      };

      # With "show the full configuration surface" preference,
      # The section below is commented out rather than left out entirely.

      # These are real d2 CLI flags that
      # just aren't in active use yet:
      #
      # animateInterval = lib.mkOption {
      #   type = lib.types.nullOr lib.types.int;
      #   default = null;
      #   description = "ms between boards when bundling multiple boards into one animated SVG.";
      # };
      # center = lib.mkOption {
      #   type = lib.types.bool;
      #   default = false;
      #   description = "Center the diagram in the rendered viewport.";
      # };
    };

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
