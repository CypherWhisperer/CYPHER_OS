# ──────────────────────────────────────────────────────────────────────────────
# src/theme/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.theme = {
    enable = lib.mkEnableOption "CypherOS-managed theming";

    # ──────────────────────────────────────────────────────────────────────────
    # Reserved for a future non-catppuccin engine. Only one value exists today —
    # this is shape reservation, not built dispatch logic.
    #
    # No branching added until a second engine is actually needed.
    # ──────────────────────────────────────────────────────────────────────────
    engine = lib.mkOption {
      type = lib.types.enum [ "catppuccin" ];
      default = "catppuccin";
      description = "Which theming engine CypherOS applies.";
    };

    flavor = lib.mkOption {
      type = lib.types.str;
      default = "mocha";
      description = ''
        Passed through to catppuccin.flavor. Typed as a plain string, not
        re-declared as an enum here — catppuccin/nix already validates its own
        accepted values; duplicating that enum risks drifting out of sync if
        catppuccin/nix ever adds flavors.
      '';
    };

    accent = lib.mkOption {
      type = lib.types.str;
      default = "mauve";
      description = "Passed through to catppuccin.accent. Same non-duplication reasoning as flavor.";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Desktop-only subset — mirrors the <category>.gui pattern from
    # ADR-023's 2026-09-05 amendment, renamed for what it actually gates: Qt/GUI
    # theming (kvantum, qt.platformTheme) that has no server relevance.
    # ──────────────────────────────────────────────────────────────────────────
    qt = {
      enable = lib.mkEnableOption "Qt/Kvantum theming (desktop only)";

      # ────────────────────────────────────────────────────────────────────────
      # platformTheme.name and style.name; carried over as is from old school
      # profile configuration.
      # ────────────────────────────────────────────────────────────────────────
      platformTheme.name = {
        type = lib.types.str;
        default = "kvantum";
        description = "QT Platform Theme Name.";
      };

      style.name = {
        type = lib.types.str;
        default = "kvantum";
        description = "QT Style Name.";
      };
    };
  };
}
