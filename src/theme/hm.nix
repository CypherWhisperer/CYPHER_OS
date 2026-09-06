# ──────────────────────────────────────────────────────────────────────────────
# src/theme/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.theme;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.engine == "catppuccin") {
      catppuccin = {
        enable = true;
        flavor = cfg.flavor;
        accent = cfg.accent;
        # ──────────────────────────────────────────────────────────────────────
        # autoEnable deliberately omitted — every consuming leaf sets its own
        # catppuccin.<app>.enable explicitly (see kitty.nix example below),
        # matching this codebase's parent+leaf gating convention rather than
        # relying on a blanket auto-apply.
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # NOTE: MOVE THESE TO THEIR RESPECTIVE FILES:
        # ──────────────────────────────────────────────────────────────────────
        # Such that each app leaf owns its own `catppuccin.<app>.enable`,
        # pulling the global signal — e.g. `src/pkgs/terminal/kitty.nix`:
        #
        # config = lib.mkIf (cfg.enable && cfg.kitty.enable) {
        #   home.packages = [ pkgs.kitty ];
        #   catppuccin.kitty.enable = lib.mkDefault config.cypher-os.theme.enable;
        #   # ... kitty program config
        # };
        # ──────────────────────────────────────────────────────────────────────
        fish.enable = true;
        nushell.enable = true;
        obs.enable = true;
        fzf.enable = true;
        k9s.enable = true;
        zellij.enable = true;
        gitui.enable = true;
        lazygit.enable = true;
        zathura.enable = true;
      };
    })

    (lib.mkIf (cfg.qt.enable && cypherOsProfile == "desktop") {
      qt = {
        enable = true;
        platformTheme.name = "kvantum";
        style.name = "kvantum";
      };
      catppuccin.kvantum.enable = lib.mkDefault true;
    })

    {
      cypher-os.theme.enable = lib.mkDefault true;
      cypher-os.theme.qt.enable = lib.mkDefault (cypherOsProfile == "desktop");
    }

    {
      assertions = [
        {
          assertion = cfg.qt.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.theme.qt.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
