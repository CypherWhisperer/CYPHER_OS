# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/claude_code.nix
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

  config = lib.mkIf (cfg.enable && cfg.claudeCode.enable) {
    home.packages = with pkgs; [ claude-code ];
  };
}
