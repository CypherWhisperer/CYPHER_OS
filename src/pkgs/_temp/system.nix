# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/_temp/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# NixOS (system) Packages deemed temporary either:
#  - During testing/ auditing/ ...
#  - Awaiting proper Declarative configuration while in use
#  -
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  #pkgs,
  config,
  ...
}:
{
  config = {
    #environment.systemPackages = with pkgs; [];
  };
}
