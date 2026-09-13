# ──────────────────────────────────────────────────────────────────────────────
# src/system/keyboard.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # KEYBOARD (SYSTEM LEVEL)
  # ────────────────────────────────────────────────────────────────────────────
  # These settings apply at the virtual console (TTY) level and to the X/Wayland
  # session before GNOME's own input-sources settings take over.
  # ────────────────────────────────────────────────────────────────────────────
  services.xserver.xkb = {
    layout = "us";
    options = "ctrl:swapcaps,menu:super,altwin:menu_win";
  };

  # ────────────────────────────────────────────────────────────────────────────
  # The above approach worked for the Ctrl-Caps swap, but failed on Super-Menu.
  # The reason keyd wins here:
  #   - XKB operates on a key symbol level and some Wayland compositors
  #     (including GNOME's Mutter) selectively honour XKB options.
  #
  #   - keyd operates on raw evdev events before any of that, so it's
  #     compositor-agnostic. It intercepts at the input device level before
  #     the compositor sees the event, so it works in both Wayland and X11,
  #     in TTYs, and everywhere.
  # ────────────────────────────────────────────────────────────────────────────
  services.keyd = {
    enable = true;
    keyboards.default = {
      # ────────────────────────────────────────────────────────────────────────
      # Replace the specific keyboard ID below if necessary, or use "*"
      # ────────────────────────────────────────────────────────────────────────
      ids = [ "*" ];
      settings = {
        # ──────────────────────────────────────────────────────────────────────
        # ATTEMPT 1
        # ──────────────────────────────────────────────────────────────────────
        # main = {
        #   # Caps Lock ↔ Ctrl (belt-and-suspenders with XKB swap)
        #   capslock = "leftcontrol";
        #   # Menu key → Super
        #   menu = "leftmeta";
        # };
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # ATTEMPT 2
        # ──────────────────────────────────────────────────────────────────────
        main = {
          # ────────────────────────────────────────────────────────────────────
          # Remap Menu key (KEY_CONTEXT_MENU) to Super (KEY_LEFTMETA)
          # Remap Super key (KEY_LEFTMETA) to Menu (KEY_CONTEXT_MENU)
          # Note: You may need to verify exact codes using "sudo keyd monitor"
          # ────────────────────────────────────────────────────────────────────
          "KEY_CONTEXT_MENU" = "KEY_LEFTMETA";
          "KEY_LEFTMETA" = "KEY_CONTEXT_MENU";
        };
      };
    };
  };
}
