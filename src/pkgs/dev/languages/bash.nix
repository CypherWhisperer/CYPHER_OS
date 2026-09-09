# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/bash.nix
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

  config = lib.mkIf (cfg.enable && cfg.bash.enable) {
    home.packages = with pkgs; [
      shellcheck # Bash linting (shellcheck.executablePath)
    ];
  };
}
