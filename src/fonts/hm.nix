# ────────────────────────────────────────────────────────────────────────
# src/fonts/hm.nix
# ────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  cypherOsLens,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.fonts;
  terminalFont = cypherOsConstants.terminalFont.pkgName;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # Full font set only installed via HM when NOT on the NixOS lens — on NixOS,
    # system.nix's fonts.packages already provides them system-wide. Installing
    # the same set again here would reintroduce the manual hm.nix/system.nix
    # sync problem ADR-024 eliminated.
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cypherOsLens != "nixos") {
      home.packages = with pkgs; [
        # ──────────────────────────────────────────────────────────────────────
        # Cantarell: GNOME's default UI font — declared here for non-NixOS
        # hosts. On NixOS it comes in via the GNOME system packages
        # automatically.
        # ──────────────────────────────────────────────────────────────────────
        cantarell-fonts
        noto-fonts-color-emoji # basic

        # ──────────────────────────────────────────────────────────────────────
        # As of November 2024, the nerdfonts package has been separated into
        # individual packages under the namespace nerd-fonts. If your system
        # throws errors or warnings about terminus-nerdfont being redundant, you
        # should replace the override method with the specific package:
        # ──────────────────────────────────────────────────────────────────────
        nerd-fonts.jetbrains-mono
        terminalFont # font for kitty + ghostty
        nerd-fonts.fira-code
        nerd-fonts.hack
        nerd-fonts.lilex
        nerd-fonts.monaspace
        nerd-fonts.noto
        nerd-fonts.roboto-mono
        nerd-fonts.ubuntu-mono
        nerd-fonts.sauce-code-pro

        # ────────────────────────────────────────────────────────────────────────
        # CURRENTLY DISABLED FONTS
        # ────────────────────────────────────────────────────────────────────────
        #fira-code

        #noto-fonts-cjk-sans
        #noto-fonts-extra

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
