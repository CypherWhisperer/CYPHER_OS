# ──────────────────────────────────────────────────────────────────────────────
# src/shell/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.shell = {
    enable = lib.mkEnableOption "CypherOS shell environment";

    zsh.enable = lib.mkEnableOption "Zsh shell environment for CypherOS";
    fish.enable = lib.mkEnableOption "Fish shell environment for CypherOS";
    nushell.enable = lib.mkEnableOption "Nushell shell environment for CypherOS";
  };
}
