# ──────────────────────────────────────────────────────────────────────────────
# src/CATEGORY/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.de.gnome;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.de.gnome.enable = lib.mkDefault (cypherOsProfile == "desktop");

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.de.gnome.enable requires cypher-os.profile.active == "desktop".
        '';
      }
    ];
  };
}
