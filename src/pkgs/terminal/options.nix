# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/terminal/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.pkgs.terminal = {
    enable = lib.mkEnableOption "CypherOS Terminal Emulators Suite and Configurations.";

    # ──────────────────────────────────────────────────────────────────────────
    # Doesn't currently have GUI packages and/or span desktop and server
    # profiles, hence no <category>.gui.* pattern
    # ──────────────────────────────────────────────────────────────────────────
    kitty.enable = lib.mkEnableOption "Ghostty terminal emulator.";
    ghostty.enable = lib.mkEnableOption "Kitty terminal emulator.";
  };
}
