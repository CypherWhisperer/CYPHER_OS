# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.editor = {
    enable = lib.mkEnableOption "CypherOS Editor applications";

    vim.enable = lib.mkEnableOption "Vim CLI text editor";

    gui = {
      enable = lib.mkEnableOption "CypherOS GUI (Graphical User Interface) Editors.";
      zettlr.enable = lib.mkEnableOption "Zettlr editor CypherOS configuration";
    };
  };
}
