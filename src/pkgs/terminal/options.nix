# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/terminal/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.terminal = {
    enable = lib.mkEnableOption "CypherOS Terminal Emulators Suite and Configurations.";

    kitty.enable = lib.mkEnableOption "Ghostty terminal emulator.";
    ghostty.enable = lib.mkEnableOption "Kitty terminal emulator.";
  };
}
