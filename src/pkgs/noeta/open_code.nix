# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/open_code.nix
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

  config = lib.mkIf (cfg.enable && cfg.openCode.enable){
    home.packages = with pkgs; [ opencode ];
  };
}
