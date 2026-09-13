# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/d2.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  # pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.languages;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.d2.enable) {
    home.packages = [ cfg.d2.package ]; # or pkgs.d2

    # ──────────────────────────────────────────────────────────────────────────
    # These env vars make the *bare CLI* (used by scripts, mdbook-d2, CI, etc.)
    # match the same defaults the editor integrations use below — without this,
    # `d2 diagram.d2 out.svg` from a terminal renders with d2's factory defaults
    # instead of CypherOS' configured Mauve theme.
    # ──────────────────────────────────────────────────────────────────────────
    home.sessionVariables = {
      D2_LAYOUT = cfg.d2.layoutEngine;
      D2_THEME = toString cfg.d2.themeId;
    }
    // lib.optionalAttrs (cfg.d2.darkThemeId != null) {
      D2_DARK_THEME = toString cfg.d2.darkThemeId;
    }
    // {
      D2_PAD = toString cfg.d2.pad;
    }
    // lib.optionalAttrs cfg.d2.sketch {
      D2_SKETCH = "1";
    };
  };
}
