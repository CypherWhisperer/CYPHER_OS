# ──────────────────────────────────────────────────────────────────────────────
# src/fonts/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  pkgs,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.fonts;

  # ────────────────────────────────────────────────────────────────────────────
  # `fonts.packages` (from `nixpkgs`'s `fonts` module) expects a list of
  # package derivations — things like `nerd-fonts.caskaydia-cove` (a package
  # attribute, which resolves to a derivation with a store path).
  # This is the reason this wouldn't work:
  #
  # terminalFontPkg = cypherOsConstants.terminalFont.pkgName;
  #
  # This resolves to a literal (and dotted) string
  # (as the type is declared in src/constants/options.nix).
  # `with pkgs; [ ... terminalFontPkg ... ]` wouldn't do attribute lookup on
  # that string — `with pkgs;` only affects bare identifiers, not the value of a
  # variable that happens to hold a string matching a package name.
  #
  # Hence Nix would try to shove the literal string "nerd-fonts.caskaydia-cove"
  # into `fonts.packages`, which expects `absolute path` (a derivation, which
  # coerces to a store path) — hence "is not of type `absolute path`." getting
  # an error:
  #
  # "A definition for option `fonts.packages."[definition 1-entry 4]"' is not of
  # type `absolute path'."
  #
  # We therefore need to leverage `lib.attrByPath` so the constant can resolve
  # to the actual package - not a string.
  # ────────────────────────────────────────────────────────────────────────────
  terminalFontPkg =
    lib.attrByPath (lib.splitString "." cypherOsConstants.terminalFont.pkgName) null
      pkgs;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = lib.mkIf cfg.enable {
    # ──────────────────────────────────────────────────────────────────────────
    # FONTS (SYSTEM LEVEL) — NixOS lens only.
    # ──────────────────────────────────────────────────────────────────────────
    # No profile check here, deliberately: every valid profile.active
    # value wants fonts on (see the mkDefault below), so there's no
    # invalid combination to gate or assert against.
    # ──────────────────────────────────────────────────────────────────────────
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

      terminalFontPkg

      # ────────────────────────────────────────────────────────────────────────
      # CURRENTLY DISABLED FONTS
      # ────────────────────────────────────────────────────────────────────────
      #fira-code

      #nerd-fonts.source-code-pro
      #nerd-fonts.cascadia-code
      #nerd-fonts.iosevka
      #nerd-fonts.victor-mono
      #nerd-fonts.meslo-lg
    ];
  };
}
