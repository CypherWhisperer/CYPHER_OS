# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/nix.nix
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

  config = lib.mkIf (cfg.enable && cfg.nix.enable) {
    home.packages = with pkgs; [
      nixd # Nix language server (nix.serverPath)

      # ────────────────────────────────────────────────────────────────────────
      # Nix formatter (nix.serverSettings.nixd.formatting.command)
      # ────────────────────────────────────────────────────────────────────────
      nixfmt-rfc-style
    ];
  };
}
