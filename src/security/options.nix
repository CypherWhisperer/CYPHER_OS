# ──────────────────────────────────────────────────────────────────────────────
# src/privacy/security.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.security = {
    enable = lib.mkEnableOption "CypherOS Security Configuration.";
    # ──────────────────────────────────────────────────────────────────────────
    # Doesn't currently span profiles, hence no <category>.gui.* pattern
    # ──────────────────────────────────────────────────────────────────────────
    keepassxc.enable = lib.mkEnableOption "KeepassXC Local-First Password Manager.";
  };
}
