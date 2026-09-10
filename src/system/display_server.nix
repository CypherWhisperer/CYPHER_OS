# ──────────────────────────────────────────────────────────────────────────────
# src/system/display_server.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # DISPLAY SERVER
  # ────────────────────────────────────────────────────────────────────────────
  # xserver.enable = true is required even for Wayland sessions on NixOS —
  # it enables the X11 infrastructure that GDM and some Wayland compositors
  # still depend on (XWayland, xauth, etc.).
  # ────────────────────────────────────────────────────────────────────────────
  services.xserver.enable = true;
}
