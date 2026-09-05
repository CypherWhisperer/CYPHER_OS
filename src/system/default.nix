# ──────────────────────────────────────────────────────────────────────────────
# src/system/default.nix
# ──────────────────────────────────────────────────────────────────────────────

{ ... }:

{
  imports = [
    ./boot
    ../profile/system.nix
    ../config/constants/system.nix
    ../de/system.nix
    ../dm/system.nix
    ../shell/system.nix
    ../fonts/system.nix
    # ./networking
    # ./security
    # ./virtualisation
  ];
}
