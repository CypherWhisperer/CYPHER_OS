# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.editor;
in
{
  imports = [
    ./options.nix
    ./vim.nix
    ./zettlr.nix
  ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.editor.enable = lib.mkDefault true;
      cypher-os.pkgs.editor.vim.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.editor.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.pkgs.editor.gui.zettlr.enable = lib.mkDefault cfg.gui.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.vim.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.editor.vim.enable requires cypher-os.pkgs.editor.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.editor.gui.enable requires cypher-os.pkgs.editor.enable.
          '';
        }

        {
          assertion = cfg.gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.pkgs.editor.gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }

        {
          assertion = cfg.gui.zettlr.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.editor.gui.zettlr.enable requires cypher-os.pkgs.editor.gui.enable.
          '';
        }
      ];
    }
  ];
}
