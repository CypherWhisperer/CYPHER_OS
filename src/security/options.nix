# ──────────────────────────────────────────────────────────────────────────────
# src/privacy/security.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.security = {
    enable = lib.mkEnableOption "CypherOS Security Configuration.";

    keepassxc.enable = lib.mkEnableOption "KeepassXC Local-First Password Manager.";
  };
}
