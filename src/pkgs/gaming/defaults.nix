# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/gaming/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.gaming;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.gaming.enable = lib.mkDefault (cypherOsProfile == "desktop");
    cypher-os.pkgs.gaming.steam.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.gaming.minecraft.enable = lib.mkDefault cfg.enable;


    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> (cypherOsProfile == "desktop");
        message = ''
          cypher-os.pkgs.gaming.enable requires cypher-os.profile.active == "desktop.
        '';
      }

      {
        assertion = cfg.steam.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.gaming.steam.enable requires cypher-os.pkgs.gaming.enable.
        '';
      }

      {
        assertion = cfg.minecraft.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.gaming.minecraft.enable requires cypher-os.pkgs.gaming.enable.
        '';
      }
    ];
  };
}
