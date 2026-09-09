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
  cfg = config.cypher-os.pkgs.dev;
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
      cypher-os.pkgs.dev.ide.enable = lib.mkDefault cfg.enable;

      cypher-os.pkgs.dev.ide.neovim.enable = lib.mkDefault cfg.ide.enable;
      cypher-os.pkgs.dev.ide.gui.enable = lib.mkDefault (cfg.ide.enable && cypherOsProfile == "desktop");
      # vscode entry -> ./vscode/default.nix
      cypher-os.pkgs.dev.ide.gui.cursor.enable = lib.mkDefault cfg.ide.gui.enable;
      cypher-os.pkgs.dev.ide.gui.webstorm.enable = lib.mkDefault cfg.ide.gui.enable;
      cypher-os.pkgs.dev.ide.gui.antigravity.enable = lib.mkDefault cfg.ide.gui.enable;
      cypher-os.pkgs.dev.ide.gui.androidStudio.enable = lib.mkDefault cfg.ide.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.ide.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.ide.enable requires cypher-os.pkgs.dev.enable.
          '';
        }

        {
          assertion = cfg.ide.neovim.enable -> cfg.ide.enable;
          message = ''
            cypher-os.pkgs.dev.ide.neovim.enable requires cypher-os.pkgs.dev.ide.enable.
          '';
        }

        {
          assertion = cfg.ide.gui.enable -> cfg.ide.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.enable requires cypher-os.pkgs.dev.ide.enable.
          '';
        }

        {
          assertion = cfg.ide.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.dev.ide.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        # vscode entry -> ./vscode/default.nix

        {
          assertion = cfg.ide.gui.cursor.enable -> cfg.ide.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.cursor.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.ide.gui.webstorm.enable -> cfg.ide.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.webstorm.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.ide.gui.antigravity.enable -> cfg.ide.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.antigravity.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.ide.gui.androidStudio.enable -> cfg.ide.gui.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.androidStudio.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }
      ];
    }
  ];
}
