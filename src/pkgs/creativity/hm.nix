# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  imports = [
    ./options.nix
    ./defaults.nix
    ./audacity.nix
    ./blender.nix
    ./gimp.nix
    ./houdini.nix
    ./inkscape.nix
    ./kdenlive.nix
    ./krita.nix
    ./penpot_hm.nix
  ];
}
