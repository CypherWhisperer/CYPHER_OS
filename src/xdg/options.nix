# ──────────────────────────────────────────────────────────────────────────────
# src/xdg/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.xdg = {
    enable = lib.mkEnableOption "CypherOS XDG configuration";
  };
}
