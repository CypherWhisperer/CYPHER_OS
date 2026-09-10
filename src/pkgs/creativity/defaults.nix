# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
}:
let
  cfg = config.cypher-os.pkgs.creativity;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.creativity.enable = lib.mkDefault (cypherOsProfile == "desktop");

    cypher-os.pkgs.creativity.penpot.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.krita.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.blender.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.houdini.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.audacity.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.gimp.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.inkscape.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.creativity.kdenlive.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.creativity.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.penpot.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.penpot.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.krita.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.krita.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.blender.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.blender.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.houdini.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.houdini.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.audacity.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.audacity.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.gimp.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.gimp.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.inkscape.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.inkscape.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
      {
        assertion = cfg.kdenlive.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.creativity.kdenlive.enable requires cypher-os.pkgs.creativity.enable.
        '';
      }
    ];
  };
}
