# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/gemini_cli.nix
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

  config = lib.mkIf (cfg.enable && cfg.geminiCli.enable) {
    home.packages = with pkgs; [ gemini-cli ];
  };
}
