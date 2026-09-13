# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/zellij.nix
# ──────────────────────────────────────────────────────────────────────────────
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.zellij.enable) {
    home.packages = with pkgs; [ zellij ];
  };
}
