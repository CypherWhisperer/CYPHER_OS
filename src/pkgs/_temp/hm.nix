# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/_temp/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Home Manager Packages deemed temporary either:
#  - During testing/ auditing/ ...
#  - Awaiting proper Declarative configuration while in use
#  -
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = {
    home.packages = with pkgs; [
      zotero
    ];
  };
}
