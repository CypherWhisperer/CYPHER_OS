# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.dev.ide = {
    enable = lib.mkEnableOption "CypherOS IDEs (Integrated Development Environment)s Suite.";
    neovim.enable = lib.mkEnableOption "CypherOS Neovim configuration (CypherIDE)";

    gui = {
      enable = lib.mkEnableOption "CypherOS GUI (Graphical User Interface) Editors.";
      # vscode entry -> ./vscode/options.nix
      cursor.enable = lib.mkEnableOption "Cursor IDE";
      webstorm.enable = lib.mkEnableOption "WebStorm IDE";
      antigravity.enable = lib.mkEnableOption "Antigravity IDE";
      androidStudio.enable = lib.mkEnableOption "Android Studio IDE";
    };
  };
}
