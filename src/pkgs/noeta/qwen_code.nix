# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/qwen_code.nix
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

  config = lib.mkIf (cfg.enable && cfg.qwenCode.enable) {
    home.packages = with pkgs; [ qwen-code ];
  };
}
