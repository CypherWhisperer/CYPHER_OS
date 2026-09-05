# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/terminal/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
{
  lib,
  config,
  cypherOsProfile,
  ...
}:

let
  cfg = config.cypher-os.pkgs.terminal;
in

{
  imports = [
    ./options.nix
    ./kitty.nix
    ./ghostty.nix
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
      cypher-os.pkgs.terminal.enable = lib.mkDefault (cypherOsProfile == "desktop");
      cypher-os.pkgs.terminal.kitty.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.terminal.ghostty.enable = lib.mkDefault cfg.enable;
    }

    {
      assertions = [
        {
          assertion = cfg.enable -> (cypherOsProfile == "desktop");
          message = ''
            cypher-os.pkgs.terminal.enable requires cypher-os.profile.active == "desktop"
          '';
        }

        {
          assertion = cfg.kitty.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.terminal.kitty.enable requires cypher-os.pkgs.terminal.enable
          '';
        }

        {
          assertion = cfg.ghostty.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.terminal.ghostty.enable requires cypher-os.pkgs.terminal.enable
          '';
        }
      ];
    }
  ];
}
