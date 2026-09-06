# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/core/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.core = {
    enable = lib.mkEnableOption "Core Packages available In CypherOS";
  };
}
