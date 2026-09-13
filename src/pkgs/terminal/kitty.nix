# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/terminal/kitty.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.terminal;
  terminalFontDisplayName = cypherOsConstants.terminalFont.displayName;
in
{
  config = lib.mkIf (cfg.enable && cfg.kitty.enable) {

    programs.kitty = {
      enable = true;

      # ── Font ────────────────────────────────────────────────────────────────
      # CaskaydiaCove Nerd Font Mono — Nerd Font variant for glyph/icon support.
      # Resolved from nerd-fonts.caskaydia-cove in home.packages.
      # ────────────────────────────────────────────────────────────────────────
      font = {
        name = terminalFontDisplayName;
        size = 10;
      };

      # ── Settings ────────────────────────────────────────────────────────────
      # programs.kitty.settings maps directly to kitty.conf key = value pairs.
      # ────────────────────────────────────────────────────────────────────────
      settings = {
        # ── Cursor ────────────────────────────────────────────────────────────
        cursor_trail = 1; # animated cursor trail
        cursor_shape = "beam"; # block | beam | underline

        # ──────────────────────────────────────────────────────────────────────
        # WINDOW
        # ──────────────────────────────────────────────────────────────────────
        window_padding_width = 1;

        # ──────────────────────────────────────────────────────────────────────
        # keep titlebars — wayland_titlebar_color handles colour
        # ──────────────────────────────────────────────────────────────────────
        hide_window_decorations = "no";

        # ── Wayland titlebar ──────────────────────────────────────────────────
        # Colours the AdwHeaderBar from the terminal background (Mocha Base)
        # rather than deferring to the libadwaita system colour-scheme.
        # This is what makes the Kitty headerbar match the terminal body.
        # ──────────────────────────────────────────────────────────────────────
        wayland_titlebar_color = "background";

        # ── Bell ──────────────────────────────────────────────────────────────
        enable_audio_bell = false;

        # ── URL ───────────────────────────────────────────────────────────────
        # Catppuccin Mocha Blue — visible and on-palette
        # ──────────────────────────────────────────────────────────────────────
        url_color = "#89b4fa";
        url_style = "curly";

        # ── Selection ─────────────────────────────────────────────────────────
        # none = keep foreground readable over selection highlight
        # ──────────────────────────────────────────────────────────────────────
        selection_foreground = "none";

        # ──────────────────────────────────────────────────────────────────────
        # Mocha Surface1 — subtle, not distracting
        # ──────────────────────────────────────────────────────────────────────
        selection_background = "#45475a";

        # ── Window Borders ────────────────────────────────────────────────────
        active_border_color = "#3d59a1";
        inactive_border_color = "#101014";
        bell_border_color = "#e0af68";

        # ── Tab Bar ───────────────────────────────────────────────────────────
        tab_bar_style = "powerline"; # powerline | fade | slant | separator
        tab_powerline_style = "slanted"; # angled | slanted | round
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        tab_fade = "1";

        # ── Scrollback ────────────────────────────────────────────────────────
        scrollback_lines = 10000;

        # ── Performance ───────────────────────────────────────────────────────
        repaint_delay = 10; # ms — lower = snappier at cost of CPU
        input_delay = 3;
        sync_to_monitor = true;

        # ── Colour palette ────────────────────────────────────────────────────
        # INTENTIONALLY ABSENT — catppuccin/nix owns all colour keys:
        # foreground, background, cursor, color0–color15, active/inactive
        # tab colours, border colours.
        #
        # Adding them here overrides catppuccin/nix.
        #
        # If overridding a single colour is needed, do it here explicitly
        # and document why it deviates from the palette.
        # ──────────────────────────────────────────────────────────────────────
      };
    };
  };
}
