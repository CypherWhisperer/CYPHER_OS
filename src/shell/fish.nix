# ──────────────────────────────────────────────────────────────────────────────
# src/shell/fish.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.fish.enable) {
    home.packages = with pkgs; [
      fish
    ];
  };
}
