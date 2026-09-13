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

{
  cypherOsConstants,
  ...
}:
let
  stateVersion = cypherOsConstants.stateVersion;
in
{
  imports = [
    ../profile/hm.nix
    ../config/constants/hm.nix
    ../theme/hm.nix

    ../de/hm.nix
    ../shell/hm.nix
    ../fonts/hm.nix
    ../xdg/hm.nix
    ../privacy/hm.nix
    ../security/hm.nix

    ../pkgs/utils/hm.nix
    ../pkgs/networking/hm.nix
    ../pkgs/cli/hm.nix
    ../pkgs/terminal/hm.nix
    ../pkgs/gaming/hm.nix
    ../pkgs/mail/hm.nix
    ../pkgs/editor/hm.nix
    ../pkgs/dev/hm.nix
    ../pkgs/browser/hm.nix
    ../pkgs/communication/hm.nix
    ../pkgs/creativity/hm.nix
    ../pkgs/media/hm.nix
    ../pkgs/noeta/hm.nix
    ../pkgs/productivity/hm.nix
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # HOME MANAGER STATE VERSION
  # ────────────────────────────────────────────────────────────────────────────
  # Set once, never change. This tells HM which release its config schema was
  # written against. It gates HM migration logic, not which packages you receive
  # ────────────────────────────────────────────────────────────────────────────
  home.stateVersion = stateVersion;
}
