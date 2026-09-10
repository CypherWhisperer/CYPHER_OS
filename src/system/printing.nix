# ──────────────────────────────────────────────────────────────────────────────
# src/system/printing.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # PRINTING
  # ────────────────────────────────────────────────────────────────────────────
  # CUPS handles printing. avahi enables mDNS printer discovery on the local
  # network (the "Add Printer" dialog in GNOME Settings finds network printers
  # via this).
  # ────────────────────────────────────────────────────────────────────────────
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
