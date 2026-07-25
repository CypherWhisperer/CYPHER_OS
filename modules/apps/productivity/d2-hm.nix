# modules/apps/productivity/d2-hm.nix

{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cypher-os.apps.productivity.d2;
in

{
  config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {
    home.packages = [ cfg.package ]; # [ (cfg.package or pkgs.d2) ];

    # These env vars make the *bare CLI* (used by scripts, mdbook-d2, CI,
    # etc.) match the same defaults the editor integrations use below —
    # without this, `d2 diagram.d2 out.svg` from a terminal renders with
    # d2's factory defaults instead of our configured Mauve theme.
    home.sessionVariables = {
      D2_LAYOUT = cfg.layoutEngine;
      D2_THEME = toString cfg.themeId;
    }
    // lib.optionalAttrs (cfg.darkThemeId != null) {
      D2_DARK_THEME = toString cfg.darkThemeId;
    }
    // {
      D2_PAD = toString cfg.pad;
    }
    // lib.optionalAttrs cfg.sketch {
      D2_SKETCH = "1";
    };
  };
}
