# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
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
      cypher-os.pkgs.cli.btop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.htop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.tmux.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.fastfetch.enable = lib.mkDefault cfg.enable;
    }

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
