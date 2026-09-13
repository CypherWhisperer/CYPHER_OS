# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/penpot_hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.creativity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.penpot.enable) {
    home.packages = with pkgs; [ penpot-desktop ];

    # ──────────────────────────────────────────────────────────────────────────
    # OPTIONAL: write a ~/.config/Penpot/ config file via home.file to
    # pre-seed the local instance URL declaratively
    # (possible but slightly fragile since Electron may overwrite it)
    # ──────────────────────────────────────────────────────────────────────────

    # ──────────────────────────────────────────────────────────────────────────
    # Handle any environment variables needed for
    # Wayland/X11, WebKit rendering flags, or GNOME integration
    # ──────────────────────────────────────────────────────────────────────────
  };
}
