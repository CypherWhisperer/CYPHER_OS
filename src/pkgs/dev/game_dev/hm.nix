# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/game_dev/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.gameDev;
in
{
  imports = [
    ./options.nix
    ./unity.nix
    ./dotnet.nix
    ./debug.nix
  ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.dev.gameDev.enable = lib.mkDefault config.cypher-os.pkgs.dev.enable;
      cypher-os.pkgs.dev.gameDev.dotnet.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.gameDev.debug.netcoredbg.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.gameDev.debug.mono.enable = lib.mkDefault cfg.enable;

      cypher-os.pkgs.dev.gameDev.gui.enable = lib.mkDefault (
        config.cypher-os.pkgs.dev.enable && cypherOsProfile == "desktop"
      );
      cypher-os.pkgs.dev.gameDev.gui.unity.enable = lib.mkDefault cfg.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.enable -> config.cypher-os.pkgs.dev.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.enable requires cypher-os.pkgs.dev.enable.
          '';
        }
        # ──────────────────────────────────────────────────────────────────────
        # GUI sub-branch:
        # ──────────────────────────────────────────────────────────────────────
        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.gui.enable requires cypher-os.pkgs.dev.gameDev.enable.
          '';
        }
        {
          assertion = cfg.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.dev.gameDev.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }
        {
          assertion = cfg.gui.unity.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.gui.unity.enable requires cypher-os.pkgs.dev.gameDev.gui.enable.
          '';
        }

        # ──────────────────────────────────────────────────────────────────────
        # Leaf gates.
        # ──────────────────────────────────────────────────────────────────────
        {
          assertion = cfg.dotnet.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.dotnet.enable requires cypher-os.pkgs.dev.gameDev.enable.
          '';
        }
        {
          assertion = (cfg.debug.netcoredbg.enable || cfg.debug.mono.enable) -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.debug.* requires cypher-os.pkgs.dev.gameDev.enable.
          '';
        }

        # ──────────────────────────────────────────────────────────────────────
        # git-lfs must be present: Unity projects routinely track large binary
        # assets, and a checkout without LFS silently yields pointer files.
        # NOTE: this checks Home Manager's `programs.git.lfs.enable`.
        # ──────────────────────────────────────────────────────────────────────
        {
          assertion = cfg.enable -> config.programs.git.lfs.enable;
          message = ''
            cypher-os.pkgs.dev.gameDev.enable requires git-lfs (programs.git.lfs.enable = true).
            Unity projects track large binary assets through Git LFS.
          '';
        }
      ];
    }
  ];
}
