# ──────────────────────────────────────────────────────────────────────────────
# src/CATEGORY/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────
# Only for categories with BOTH hm.nix and system.nix — see
# docs/contributing/conventions/gating_and_assertions.md §13.
#
# If the category only has one of the two, don't use this template file and
# simply fold defaults and assertions into that one file instead.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.CATEGORY;
in
{
  imports = [ ./options.nix ];

  config = {

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: pick ONE shape for the category's own top-level enable, don't leave
    # both:
    #   Both-profile category: CHECK TEMPLATE BELOW
    #   Desktop-only category: CHECK TEMPLATE BELOW
    #   Server-only category:  CHECK TEMPLATE BELOW
    #
    # Pair defaults configurations with with the matching assertion below.
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # GENERIC DEFAULT CONFIG TEMPLATE.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.CATEGORY.enable = lib.mkDefault (CONDITION);

    # ──────────────────────────────────────────────────────────────────────────
    # FOR CATEGORIES ONLY VALID IN THE DESKTOP PROFILE.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.CATEGORY.enable = lib.mkDefault (cypherOsProfile == "desktop");

    # ──────────────────────────────────────────────────────────────────────────
    # FOR CATEGORIES ONLY VALID IN THE SERVER PROFILE.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.CATEGORY.enable = lib.mkDefault (cypherOsProfile == "server");

    # ──────────────────────────────────────────────────────────────────────────
    # FOR CATEGORIES SPANNING BOTH SERVER AND DESKTOP PROFILES AND HAVE
    # GUI PACKAGES.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.CATEGORY.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");


    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      # ────────────────────────────────────────────────────────────────────────
      # GENERIC ASSERTION TEMPLATE
      # ────────────────────────────────────────────────────────────────────────
      {
        assertion = cfg.CATEGORY.enable -> (CONDITION);
        message = ''
          cypher-os.CATEGORY.enable requires (CONDITION).
        '';
      }

      # ────────────────────────────────────────────────────────────────────────
      # FOR CATEGORIES ONLY VALID IN THE DESKTOP PROFILE.
      # ────────────────────────────────────────────────────────────────────────
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.CATEGORY.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      # ────────────────────────────────────────────────────────────────────────
      # FOR CATEGORIES ONLY VALID IN THE SERVER PROFILE.
      # ────────────────────────────────────────────────────────────────────────
      {
        assertion = cfg.enable -> cypherOsProfile == "server";
        message = ''
          cypher-os.CATEGORY.enable requires cypher-os.profile.active == "server".
        '';
      }

      # ────────────────────────────────────────────────────────────────────────
      # FOR CATEGORIES SPANNING BOTH SERVER AND DESKTOP PROFILES AND HAVE
      # GUI PACKAGES.
      # ────────────────────────────────────────────────────────────────────────
      {
        # ──────────────────────────────────────────────────────────────────────
        # First gate the parrent category to .gui namespace sub-branch.
        # ──────────────────────────────────────────────────────────────────────
        assertion = cfg.gui.enable -> cfg.enable;
        message = ''
          cypher-os.CATEGORY.gui.enable requires cypher-os.CATEGORY.enable.
        '';
      }

      {
        # ──────────────────────────────────────────────────────────────────────
        # Second gate to ensure the desktop profile is active (i.e., GUI pkgs).
        # ──────────────────────────────────────────────────────────────────────
        # Stated once here — every leaf under gui.* inherits this via the
        # leaf-implies-gui.enable assertion below, transitively.
        # ──────────────────────────────────────────────────────────────────────
        assertion = cfg.CATEGORY.gui.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.CATEGORY.gui.enable requires cypher-os.profile.active == "desktop".
        '';
      }
    ];
  };
}
