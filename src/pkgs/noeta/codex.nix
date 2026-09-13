# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/codex.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.codex.enable) {
    home.packages = with pkgs; [ codex ];
  };
}
