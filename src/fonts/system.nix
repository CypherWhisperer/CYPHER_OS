# ────────────────────────────────────────────────────────────────────────
# src/fonts/system.nix
# ────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.cypher-os.fonts;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # ────────────────────────────────────────────────────────────────────────
      # FONTS (SYSTEM LEVEL) — NixOS lens only.
      # ────────────────────────────────────────────────────────────────────────
      # No profile check here, deliberately: every valid profile.active
      # value wants fonts on (see the mkDefault below), so there's no
      # invalid combination to gate or assert against.
      # ────────────────────────────────────────────────────────────────────────
      fonts.fontDir.enable = true;
      fonts.enableGhostscriptFonts = true;
      fonts.packages = with pkgs; [
        cantarell-fonts

        noto-fonts
        noto-fonts-color-emoji

        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.hack
        nerd-fonts.lilex
        nerd-fonts.monaspace
        nerd-fonts.noto
        nerd-fonts.roboto-mono
        nerd-fonts.ubuntu-mono
        nerd-fonts.sauce-code-pro

        # ──────────────────────────────────────────────────────────────────────
        # CURRENTLY DISABLED FONTS
        # ──────────────────────────────────────────────────────────────────────
        #fira-code

        #nerd-fonts.source-code-pro
        #nerd-fonts.cascadia-code
        #nerd-fonts.iosevka
        #nerd-fonts.victor-mono
        #nerd-fonts.meslo-lg
      ];
    })

    { cypher-os.fonts.enable = lib.mkDefault true; }
  ];
}
