# ──────────────────────────────────────────────────────────────────────────────
# src/system/default.nix
# ──────────────────────────────────────────────────────────────────────────────

{ ... }:

{
  imports = [
    ./boot
    ./virtualisation/system.nix
    ./networking
    # ./security

    ./bluetooth.nix
    ./display_server.nix
    ./keyboard.nix
    ./locale_and_time.nix
    ./nix_settings.nix
    ./packages.nix
    ./printing.nix
    ./sound.nix
    ./swap.nix
    ./zram.nix

    ../profile/system.nix
    ../config/constants/system.nix
    ../de/system.nix
    ../dm/system.nix
    ../shell/system.nix
    ../fonts/system.nix
    ../users/system.nix
    ../pkgs/gaming/system.nix
    ../pkgs/mail/system.nix
    ../pkgs/dev/system.nix
    ../pkgs/browser/system.nix
    ../pkgs/creativity/system.nix
    ../pkgs/productivity/system.nix
    ../pkgs/devops/system.nix
  ];
}
