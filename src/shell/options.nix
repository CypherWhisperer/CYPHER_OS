# ──────────────────────────────────────────────────────────────────────────────
# src/shell/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.shell = {
    enable = lib.mkEnableOption "CypherOS shell environment";
    # ──────────────────────────────────────────────────────────────────────────
    # bash is intentionally excluded from this namespace because it's the
    # NixOS-provided baseline, present unconditionally regardless of profile.
    # ──────────────────────────────────────────────────────────────────────────
    zsh.enable = lib.mkEnableOption "Zsh shell environment for CypherOS";
    fish.enable = lib.mkEnableOption "Fish shell environment for CypherOS";
    nushell.enable = lib.mkEnableOption "Nushell shell environment for CypherOS";
  };
}
