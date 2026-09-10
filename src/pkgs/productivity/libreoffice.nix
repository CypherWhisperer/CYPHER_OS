# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/libreoffice.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;

  ctpLO = pkgs.fetchurl {
    # ──────────────────────────────────────────────────────────────────────────
    # Catppuccin Mocha Mauve .soc
    # ──────────────────────────────────────────────────────────────────────────
    url = "https://github.com/catppuccin/libreoffice/raw/main/themes/mocha/mauve/catppuccin-mocha-mauve.soc";
    sha256 = "sha256-c7BIwKlwUpD+rLKQQi43mHi2s/hlNkxPE+eX7iWb2vI=";
  };
in

{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.libreOffice.enable) {
    home.packages = with pkgs; [ libreoffice ];

    home.file.".config/libreoffice/4/user/config/catppuccin-mocha-mauve.soc".source = ctpLO;

    # ──────────────────────────────────────────────────────────────────────────
    # LibreOffice on NixOS frequently needs `SAL_USE_VCLPLUGIN=gtk3` set
    # explicitly as an environment variable, otherwise it falls back to its own
    # VCL widget system. Setting the env var forces LibreOffice to use the GTK3
    # rendering backend, at which point it will respect the system's GTK3 theme.
    # ──────────────────────────────────────────────────────────────────────────
    home.sessionVariables = {
      SAL_USE_VCLPLUGIN = "gtk3";
    };
  };
}
