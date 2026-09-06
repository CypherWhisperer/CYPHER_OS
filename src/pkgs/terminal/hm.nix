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
    # DEFAULT CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.terminal.enable = lib.mkDefault (cypherOsProfile == "desktop");
      cypher-os.pkgs.terminal.kitty.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.terminal.ghostty.enable = lib.mkDefault cfg.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
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
