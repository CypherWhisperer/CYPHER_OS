# ──────────────────────────────────────────────────────────────────────────────
# src/system/virtulisation/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.virtualisation.helpers.enable =
    lib.mkEnableOption "virtualisation helpers (distrobox, winboat, vagrant, virt-viewer)";
}
