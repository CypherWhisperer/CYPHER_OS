# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:

{
  options.cypher-os.pkgs.cli = {
    enable = lib.mkEnableOption "CLI applications";

    btop.enable = lib.mkEnableOption "btop inteructive resource monitor";
    htop.enable = lib.mkEnableOption "htop process viewer (lighter than btop)";
    tmux.enable = lib.mkEnableOption "tmux terminal multiplexer";
    zellij.enable = lib.mkEnableOption "zellij terminal multiplexer";
    fastfetch.enable = lib.mkEnableOption "fastfetch system info";
  };
}
