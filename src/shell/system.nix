# ──────────────────────────────────────────────────────────────────────────────
# src/shell/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  lib,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [
    ./options.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable && cfg.zsh.enable) {
      # ──────────────────────────────────────────────────────────────────────
      # ZSH (SYSTEM LEVEL)
      # ──────────────────────────────────────────────────────────────────────
      # Setting the user shell to zsh - as done - requires zsh to be enabled
      # at the system level — NixOS won't add it to /etc/shells otherwise,
      # which breaks login.
      # ──────────────────────────────────────────────────────────────────────
      programs.zsh.enable = true;
    })

    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable && cfg.fish.enable) {
      programs.fish.enable = true;
    })

    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable && cfg.nushell.enable) {
      programs.nushell.enable = true;
    })

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
