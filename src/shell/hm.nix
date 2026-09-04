# ──────────────────────────────────────────────────────────────────────────────
# src/shell/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:

let
  cfg = config.cypher-os.shell;
in

{
  imports = [
    ./options.nix
    ./zsh.nix
    ./nushell.nix
    ./fish.nix
  ];

  config = lib.mkMerge [
    # Currently no logic to gate:
    # (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {})

    {
      cypher-os.shell.zsh.enable = lib.mkDefault (cypherOsProfile == "desktop" && cfg.enable);
      cypher-os.shell.fish.enable = lib.mkDefault (cypherOsProfile == "desktop" && cfg.enable);
      cypher-os.shell.nushell.enable = lib.mkDefault (cypherOsProfile == "desktop" && cfg.enable);

    }

    {
      cypher-os.shell.enable = lib.mkDefault (cypherOsProfile == "desktop");
    }

    {
      assertions = [
        {
          assertion = cfg.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.shell.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
