# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/dart.nix
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

  config = lib.mkIf (cfg.enable && cfg.dart.enable) {
    home.packages = with pkgs; [
      flutter # includes dart SDK
    ];
  };
}
