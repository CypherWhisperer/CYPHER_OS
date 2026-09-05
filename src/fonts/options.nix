# ──────────────────────────────────────────────────────────────────────────────
# src/fonts/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.fonts = {
    enable = lib.mkEnableOption "the CypherOS fonts stack";
  };
}
