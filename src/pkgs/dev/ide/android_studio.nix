# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/android_studio.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.androidStudio.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: bare install — configure SDK via UI.
      # ────────────────────────────────────────────────────────────────────────
      # I.e.,
      # bundles emulator, SDK manager, AVD manager
      # ────────────────────────────────────────────────────────────────────────
      android-studio
    ];
  };
}
