# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/L.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  # pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.L.enable) {
    # home.packages = with pkgs; [   ];

    # Not currently in nixpkgs (at least under the name hermes). Might have to
    # package ourselves
  };
}
