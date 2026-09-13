# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/zathura.nix
# ──────────────────────────────────────────────────────────────────────────────
# Zathura — minimalist, keyboard-driven document viewer (PDF, DjVu, PS, CB).
#
# Managed via HM's programs.zathura module; required for catppuccin/nix
# to inject the Catppuccin theme. Installing zathura via
# environment.systemPackages bypasses the catppuccin hook.
#
# Sources:
#   https://nix.catppuccin.com/options/v1.1/home/programs.zathura/
#   https://mynixos.com/home-manager/options/programs.zathura
#   https://pwmt.org/projects/zathura/documentation/ (zathurarc man page)
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.zathura.enable) {
    programs.zathura = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # ── Options — zathurarc(5) key-value pairs:
      # ────────────────────────────────────────────────────────────────────────
      # These merge with whatever catppuccin/nix writes; catppuccin handles
      # all colour keys so we focus on behaviour and UX here.
      # ────────────────────────────────────────────────────────────────────────
      options = {
        # ──────────────────────────────────────────────────────────────────────
        # Reflow mode: automatically reflow text for the window width.
        # Particularly useful for academic papers and ebooks.
        # ──────────────────────────────────────────────────────────────────────
        recolor = false;

        # ──────────────────────────────────────────────────────────────────────
        # catppuccin/nix sets its own recolor keys; leave false
        # to let the Catppuccin palette drive foreground/background
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # Render backends — mupdf renders faster than poppler for large PDFs.
        # The backend is set at compile time via the package;
        # this is informational.
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # Page layout
        # ──────────────────────────────────────────────────────────────────────
        pages-per-row = 1; # single-page view by default
        first-page-column = "1:1"; # odd pages on left in dual-page mode

        # ──────────────────────────────────────────────────────────────────────
        # Scroll behaviour
        # ──────────────────────────────────────────────────────────────────────
        scroll-step = 50; # pixels per scroll event
        smooth-scroll = true;

        # ──────────────────────────────────────────────────────────────────────
        # Zoom
        # ──────────────────────────────────────────────────────────────────────
        zoom-min = 10;
        zoom-max = 1000;
        zoom-step = 10;

        # ──────────────────────────────────────────────────────────────────────
        # Window chrome
        # ──────────────────────────────────────────────────────────────────────
        window-title-basename = true; # show filename only, not full path
        window-title-page = true; # append current page number to title
        statusbar-home-tilde = true; # abbreviate $HOME as ~ in statusbar

        # ──────────────────────────────────────────────────────────────────────
        # Clipboard — use primary selection (middle-click) for yanked text
        # ──────────────────────────────────────────────────────────────────────
        selection-clipboard = "clipboard"; # "primary" | "clipboard"

        # ──────────────────────────────────────────────────────────────────────
        # Sandbox — none is required on NixOS where seccomp filtering is
        # handled by the kernel; strict may break plugin loading.
        # ──────────────────────────────────────────────────────────────────────
        sandbox = "none";
      };

      # ────────────────────────────────────────────────────────────────────────
      # ── Key mappings — zathurarc(5) :map syntax
      # ────────────────────────────────────────────────────────────────────────
      mappings = {
        # ──────────────────────────────────────────────────────────────────────
        # Vim-style half-page navigation
        # ──────────────────────────────────────────────────────────────────────
        "<C-d>" = "scroll half-down";
        "<C-u>" = "scroll half-up";

        # ──────────────────────────────────────────────────────────────────────
        # Rotate pages
        # ──────────────────────────────────────────────────────────────────────
        "r" = "rotate rotate-cw";
        "R" = "rotate rotate-ccw";

        # ──────────────────────────────────────────────────────────────────────
        # Fit modes
        # ──────────────────────────────────────────────────────────────────────
        "W" = "adjust_window best-fit";
        "P" = "adjust_window width";

        # ──────────────────────────────────────────────────────────────────────
        # Toggle dual-page view
        # ──────────────────────────────────────────────────────────────────────
        "D" = "toggle_page_mode";

        # ──────────────────────────────────────────────────────────────────────
        # Reload document (useful when source file updates)
        # ──────────────────────────────────────────────────────────────────────
        "<C-r>" = "reload";
      };

      # ────────────────────────────────────────────────────────────────────────
      # ── Extra config — raw zathurarc lines:
      # ────────────────────────────────────────────────────────────────────────
      # Use for anything not expressible via options/mappings attrsets.
      # ────────────────────────────────────────────────────────────────────────
      extraConfig = ''
        # Include statement example (uncomment if splitting config):
        # include ~/.config/zathura/local.conf
      '';
    };
  };
}
