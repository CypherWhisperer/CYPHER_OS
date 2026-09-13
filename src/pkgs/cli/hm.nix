# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;
in
{
  imports = [
    ./options.nix
    ./btop.nix
    ./htop.nix
    ./tmux.nix
    ./zellij.nix
    ./fastfetch.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        # ──────────────────────────────────────────────────────────────────────
        # Mermaid tooling
        # ──────────────────────────────────────────────────────────────────────
        mermaid-cli # mmdc binary — render .mmd → SVG/PNG
        #mermaid-filter # if using pandoc export pipelines
      ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.cli.btop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.htop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.tmux.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.fastfetch.enable = lib.mkDefault cfg.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.btop.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.btop.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.htop.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.htop.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.tmux.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.tmux.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.fastfetch.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.fastfetch.enable requires cypher-os.pkgs.cli.enable.
          '';
        }
      ];
    }
  ];
}
