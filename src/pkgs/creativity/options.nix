# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.creativity = {
    enable = lib.mkEnableOption "CypherOS creativity packages suite";

    penpot.enable = lib.mkEnableOption "Penpot Design App";
    krita.enable = lib.mkEnableOption "Krita 2D Design and Art App";
    blender.enable = lib.mkEnableOption "Blender 3D Design App";
    houdini.enable = lib.mkEnableOption "Houdini 3D Design App";
    audacity.enable = lib.mkEnableOption "Audacity Audio Manipulation App";
    gimp.enable = lib.mkEnableOption "Gimp (GNU Image Manipulation Program) App";
    inkscape.enable = lib.mkEnableOption "Inkscape Vector Graphics Manipulation App";
    kdenlive.enable = lib.mkEnableOption "Kdenlive Videography and media manipulation App";
  };
}
