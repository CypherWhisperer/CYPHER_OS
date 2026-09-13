# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/fastfetch.nix
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
#   - fastfetch config.jsonc (deployed via xdg.configFile)
#   - PNG artwork directory deployment (configs/system/fastfetch/pngs/)
#
# ──────────────────────────────────────────────────────────────────────────────
# RANDOM PNG LOGO STRATEGY:
#   The config uses a shell command to randomly select a PNG from the pngs/
#   directory at runtime. This works because fastfetch evaluates the `source`
#   field as a shell command when it begins with $(...).
#
# ──────────────────────────────────────────────────────────────────────────────
#   XDG_CONFIG_HOME resolves correctly under XDG profile separation, so the
#   pngs directory is always found at the right profile-specific path.
#
# ──────────────────────────────────────────────────────────────────────────────
# ADDING THE NIXOS LOGO PNG:
#   The official NixOS snowflake logo is available as an SVG in pkgs.nixos-icons.
#   For PNG, two options:
#     Option A (recommended): Download the official PNG from
#       https://github.com/NixOS/nixos-artwork/icons/ and place it in
#       configs/system/fastfetch/pngs/nixos.png in the repo.
#
#     Option B: Convert the SVG at build time using pkgs.imagemagick:
#       convert\
#       ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg\
#       nixos.png
#
#   Place whichever PNG files you want in whatever
#   cypherOsConstants.fastfetchArtworkPngsRoot point to — they'll all be
#   deployed and the random selector picks from all of them.
#
# ──────────────────────────────────────────────────────────────────────────────
# PNG REQUIREMENTS FOR KITTY DISPLAY:
#   - No background (transparent PNG) gives the cleanest look
#   - Reasonable resolution: 256×256 to 512×512 is ideal
#   - The `height = 18` in the config constrains the display height in
#     terminal rows
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.fastfetch.enable) {
    home.packages = with pkgs; [ fastfetch ];

    # ── PNG Artwork Directory ─────────────────────────────────────────────────
    # Deploys the entire pngs/ directory from the repo. Add or remove PNG files
    # in cypherOsConstants.fastfetchArtworkPngsRoot and run
    # home-manager switch — they'll appear in the rotation automatically.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."fastfetch/pngs" = {
      source = cypherOsConstants.fastfetchArtworkPngsRoot;
      recursive = true;
    };

    # ── fastfetch Configuration ───────────────────────────────────────────────
    xdg.configFile."fastfetch/config.jsonc" = {
      text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

        logo = {
          # ────────────────────────────────────────────────────────────────────
          # Shell command: randomly select one PNG from the deployed pngs
          # directory. fastfetch evaluates $(...) in source at runtime
          # via /bin/sh.
          # ────────────────────────────────────────────────────────────────────
          source = ''$(find "''${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/pngs/" -name "*.png" | shuf -n 1)'';
          height = 18;
          # ────────────────────────────────────────────────────────────────────
          # padding: adds vertical breathing room so the logo doesn't crowd info
          # ────────────────────────────────────────────────────────────────────
          padding = {
            top = 1;
            bottom = 1;
          };
        };

        display = {
          separator = " : ";
          # ────────────────────────────────────────────────────────────────────
          # Use Catppuccin Mocha palette for key colors
          # (individual module keyColor values below override per section)
          # ────────────────────────────────────────────────────────────────────
          color = {
            keys = "blue"; # Catppuccin Mocha Blue
            title = "38;2;224;130;255"; # "mauve";   # Catppuccin Mocha Mauve
            output = "38;2;224;130;255";
          };
        };

        modules = [
          # ── Header ──────────────────────────────────────────────────────────
          {
            type = "custom";
            format = "\u001b[38;2;137;180;250m   󰄛  コンピューター";
            # #89b4fa = Catppuccin Mocha Blue — matches the palette exactly
          }
          {
            type = "custom";
            format = "┌──────────────────────────────────────────────────┐";
          }

          # ── System Info ─────────────────────────────────────────────────────
          {
            type = "chassis";
            key = "  󰇺 Chassis";
            format = "{3}";
            keyColor = "blue";
          }
          {
            type = "os";
            key = "  󰣇 OS";
            format = "{2}";
            keyColor = "red";
          }
          {
            type = "kernel";
            key = "  Kernel";
            format = "{2}";
            keyColor = "red";
          }
          {
            type = "packages";
            key = "  󰏗 Packages";
            keyColor = "green";
          }
          {
            type = "display";
            key = "  󰍹 Display";
            format = "{1}x{2} @ {3}Hz [{7}]";
            keyColor = "green";
          }
          {
            type = "terminal";
            key = "  >_ Terminal";
            keyColor = "yellow";
          }
          {
            type = "wm";
            key = "  󱗃 WM";
            format = "{2}";
            keyColor = "yellow";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────┘";
          }

          "break"

          # ── Identity ────────────────────────────────────────────────────────
          {
            type = "title";
            key = "  ";
            format = "{6} {7} {8}";
          }

          # ── Hardware ────────────────────────────────────────────────────────
          {
            type = "custom";
            format = "┌──────────────────────────────────────────────────┐";
          }
          {
            type = "cpu";
            format = "{1} @ {7}";
            key = "   CPU";
            keyColor = "blue";
          }
          {
            type = "gpu";
            format = "{1} {2}";
            key = "  󰊴 GPU";
            keyColor = "blue";
          }
          {
            type = "gpu";
            format = "{3}";
            key = "   GPU Driver";
            keyColor = "38;2;224;130;255"; # "mauve";
          }
          {
            type = "memory";
            key = "    Memory";
            keyColor = "38;2;224;130;255"; # "mauve";
          }
          {
            type = "command";
            key = "  󱦟 OS Age";
            keyColor = "red";
            text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
          }
          {
            type = "uptime";
            key = "  󱫐 Uptime";
            keyColor = "red";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────┘";
          }

          # ── Color Palette ───────────────────────────────────────────────────
          {
            type = "colors";
            paddingLeft = 2;
            symbol = "circle";
          }

          "break"
        ];
      };
    };
  };
}
