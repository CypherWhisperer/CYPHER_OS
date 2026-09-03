# ──────────────────────────────────────────────────────────────────────────────
# src/de/gnome/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os.de.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };
}
