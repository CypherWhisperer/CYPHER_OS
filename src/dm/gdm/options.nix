# ──────────────────────────────────────────────────────────────────────────────
# src/dm/gdm/options.nix
# ──────────────────────────────────────────────────────────────────────────────
{ lib, ... }:

{
  options.cypher-os.dm.gdm.enable = lib.mkEnableOption "GDM (Gnome Display Manager) display manager";
}
