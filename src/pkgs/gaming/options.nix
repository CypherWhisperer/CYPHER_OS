# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/gaming/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.gaming = {
    enable = lib.mkEnableOption "CypherOS Gaming Configuration.";
    steam.enable = lib.mkEnableOption "Steam and gaming infrastructure.";
    minecraft.enable = lib.mkEnableOption "Minecraft and related gaming infrastructure.";
  };
}
