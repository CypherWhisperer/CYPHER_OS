# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/core/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.pkgs.core = {
    enable = lib.mkEnableOption "Core Packages available In CypherOS";
    # ──────────────────────────────────────────────────────────────────────────
    # Doesn't currently have GUI packages and/or span desktop and server
    # profiles, hence no <category>.gui.* pattern
    # ──────────────────────────────────────────────────────────────────────────
  };
}
