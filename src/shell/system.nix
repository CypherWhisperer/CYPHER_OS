# ──────────────────────────────────────────────────────────────────────────────
# src/shell/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  lib,
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
    (lib.mkIf (cfg.enable && cfg.zsh.enable) {
      # ────────────────────────────────────────────────────────────────────────
      # ZSH (SYSTEM LEVEL)
      # ────────────────────────────────────────────────────────────────────────
      # Setting the user shell to zsh - as done - requires zsh to be enabled
      # at the system level — NixOS won't add it to /etc/shells otherwise,
      # which breaks login.
      # ────────────────────────────────────────────────────────────────────────
      programs.zsh.enable = true;
    })

    # ──────────────────────────────────────────────────────────────────────────
    # FISH (SYSTEM LEVEL)
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.fish.enable) {
      programs.fish.enable = true;
    })

    # ──────────────────────────────────────────────────────────────────────────
    # NUSHELL (SYSTEM LEVEL)
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.nushell.enable) {
      programs.nushell.enable = true;
    })

    {
      cypher-os.shell.enable = lib.mkDefault true;
    }
  ];
}
