# ──────────────────────────────────────────────────────────────────────────────
# src/home/default.nix
# ──────────────────────────────────────────────────────────────────────────────
# Home Manager evaluation root for CypherOS.
#
# RESPONSIBILITIES:
#   1. Unconditionally import/aggregate all HM-related module
#   2. Own home.stateVersion — set once, never change.
#   3. Own nothing else. DE config, app config, and profile defaults all live
#      in their respective modules categories.
# ──────────────────────────────────────────────────────────────────────────────

{ cypherOsConstants, ... }:

{
  imports = [
    ../profile/hm.nix
    ../de/hm.nix
    ../shell/hm.nix
    ../fonts/hm.nix
    ../xdg/hm.nix
    ../privacy/hm.nix
    ../security/hm.nix
    ../pkgs/utils/hm.nix
    ../pkgs/networking/hm.nix

    # ──────────────────────────────────────────────────────────────────────────
    # An error I hit in prior build:
    # (error: error parsing derivation
    # '/nix/store/nzhz804z407sw3zi40ls5h71jdsgcpgm-home-manager-auto-expire.
    # service.drv':
    #
    # file is empty (possible filesystem corruption))
    # ──────────────────────────────────────────────────────────────────────────
    # ./gc-hm.nix
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # HOME MANAGER STATE VERSION
  # ────────────────────────────────────────────────────────────────────────────
  # Set once, never change. This tells HM which release its config schema was
  # written against. It gates HM migration logic, not which packages you receive.
  home.stateVersion = cypherOsConstants.stateVersion;
}
