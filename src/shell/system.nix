# ──────────────────────────────────────────────────────────────────────────────
# src/shell/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.zsh.enable) {
      # ────────────────────────────────────────────────────────────────────────
      # ZSH (SYSTEM LEVEL ENABLEMENT).
      # ────────────────────────────────────────────────────────────────────────
      # Setting the user shell to zsh - as done - requires zsh to be enabled
      # at the system level — NixOS won't add it to /etc/shells otherwise,
      # which breaks login.
      # ────────────────────────────────────────────────────────────────────────
      programs.zsh.enable = true;
    })

    # ──────────────────────────────────────────────────────────────────────────
    # FISH (SYSTEM LEVEL ENABLEMENT).
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.fish.enable) {
      programs.fish.enable = true;
    })

    # ──────────────────────────────────────────────────────────────────────────
    # NUSHELL (SYSTEM LEVEL ENABLEMENT).
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.nushell.enable) {
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: got error: The option `programs.nushell' does not exist.
      # ────────────────────────────────────────────────────────────────────────
      #programs.nushell.enable = true;

      environment.systemPackages = with pkgs; [ nushell ];
    })
  ];
}
