# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/t3_code.nix
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

  config = lib.mkIf (cfg.enable && cfg.t3Code.enable){
    home.packages = with pkgs; [ t3code ];
  };
}
