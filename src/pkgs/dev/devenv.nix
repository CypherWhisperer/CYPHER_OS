# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/devenv.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# devenv + direnv work 2gether for per-project declarative development
# environments.
#
# devenv: a Nix-based tool for declaring reproducible project shells with
#   services (MySQL, Redis, etc.), language toolchains, and process management.
#   Invoked per-project via `devenv shell` or `devenv up`.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.devenv.enable) {
    home.packages = with pkgs; [
      devenv
    ];
  };
}
