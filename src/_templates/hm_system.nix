# ──────────────────────────────────────────────────────────────────────────────
# src/CATEGORY/{hm,system}.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.CATEGORY;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [

    # ──────────────────────────────────────────────────────────────────────────
    # GENERIC GATING TEMPLATE.
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && (CONDITION)) {
      # Logic
    })

    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: PACKAGES/CONFIGURATION ELIGIBLE FOR BOTH SERVER AND DESKTOP PROFILES
    # ARE ONLY GATED BY (cfg.enable), I.E:
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf cfg.enable {
      # Logic
    })

    # ──────────────────────────────────────────────────────────────────────────
    # PACKAGES/CONFIGS ELIGIBLE FOR BOTH SERVER AND DESKTOP PROFILES, AND HAVE
    # GUI PACKAGES
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.gui.enable) {
      # Logic
    })

    # ──────────────────────────────────────────────────────────────────────────
    # PACKAGES/CONFIGS ONLY ELIGIBLE FOR DESKTOP PROFILE:
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {
      # Logic
    })

    # ──────────────────────────────────────────────────────────────────────────
    # PACKAGES/CONFIGS ONLY ELIGIBLE FOR SERVER PROFILE:
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cypherOsProfile == "server" && cfg.enable) {
      # Logic
    })

    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: THE SECTIONS BELOW (i.e., defaults configuration and assertions)
    #       ONLY APPEAR WHEN THEY ARE EXCLUSIVE TO ONE EVALUATION CONTEXT
    #       (i.e.,
    #        `programs.*`, `services.*`     -> NixOS system side.
    #        `home.file.*`, `home.packages` -> HM side.
    #       )
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      # NOTE: REFER TO src/_templates/defaults.nix FOR STRUCTURE, TEMPLATES
      # AND CONVENTIONS.
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        # NOTE: REFER TO src/_templates/defaults.nix FOR STRUCTURE, TEMPLATES
        # AND CONVENTIONS.
      ];
    }
  ];
}
