# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/kotlin.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.languages;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.kotlin.enable) {
    home.packages = with pkgs; [
      kotlin
      # kotlin-language-server

      # ────────────────────────────────────────────────────────────────────────
      # adb + fastboot — enable when you start using a device
      # ────────────────────────────────────────────────────────────────────────
      android-tools
    ];
  };
}
