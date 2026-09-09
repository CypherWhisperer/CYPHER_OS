# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.ide;
in
{
  imports = [
    ./options.nix
    ./neovim.nix
    ./vscode
    ./cursor.nix
    ./webstorm.nix
    ./antigravity.nix
    ./android_studio.nix
  ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.dev.ide.enable = lib.mkDefault true;
      cypher-os.pkgs.dev.ide.neovim.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.ide.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      # vscode entry -> ./vscode/default.nix
      cypher-os.pkgs.dev.ide.gui.cursor.enable = lib.mkDefault cfg.gui.enable;
      cypher-os.pkgs.dev.ide.gui.webstorm.enable = lib.mkDefault cfg.gui.enable;
      cypher-os.pkgs.dev.ide.gui.antigravity.enable = lib.mkDefault cfg.gui.enable;
      cypher-os.pkgs.dev.ide.gui.androidStudio.enable = lib.mkDefault cfg.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.neovim.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.ide.neovim.enable requires cypher-os.pkgs.dev.ide.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.enable requires cypher-os.pkgs.dev.ide.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.dev.ide.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        # vscode entry -> ./vscode/default.nix

        {
          assertion = cfg.gui.cursor.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.cursor.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.gui.webstorm.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.webstorm.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.gui.antigravity.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.antigravity.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.gui.androidStudio.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.androidStudio.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }
      ];
    }
  ];
}
