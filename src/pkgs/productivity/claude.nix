# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/claude.nix
# ──────────────────────────────────────────────────────────────────────────────
# IMPORTANT: This module handles only the user-space side.
# The overlay that makes pkgs.claude-desktop available MUST BE (and IS)
# registered at the NixOS system level in (flake/nixpkgs_config.nix).
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.claude.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # ── Package:
    # ──────────────────────────────────────────────────────────────────────────
    # The package is injected into pkgs by the system-level overlay.
    # Home Manager installs it into the user profile from there.
    # ──────────────────────────────────────────────────────────────────────────
    home.packages = [ pkgs.claude-desktop ];

    # ──────────────────────────────────────────────────────────────────────────
    # ── Wayland / display server environment:
    # ──────────────────────────────────────────────────────────────────────────
    # Claude Desktop is Electron-based. On a Wayland session (GNOME on Wayland)
    # it needs these flags to run natively rather than falling back to XWayland.
    #
    # OZONE_PLATFORM tells Chromium/Electron to use the Wayland backend.
    # ELECTRON_OZONE_PLATFORM_HINT=auto lets it decide at runtime — safer than
    # hardcoding "wayland" because it gracefully falls back on XWayland sessions
    # ──────────────────────────────────────────────────────────────────────────
    home.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── MCP configuration:
    # ──────────────────────────────────────────────────────────────────────────
    # ~/.config/Claude/claude_desktop_config.json is the canonical MCP config
    # location. Manage here declaratively so it's version-controlled.
    #
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: This path is relative to XDG_CONFIG_HOME.
    # ──────────────────────────────────────────────────────────────────────────
    # Because src/de/gnome/hm.nix sets XDG_CONFIG_HOME=~/.config/profiles/gnome
    # for the GNOME session, Claude Desktop will read from:
    #  - ~/.config/profiles/gnome/Claude/claude_desktop_config.json
    #
    # when launched inside the GNOME XDG profile. This is correct behaviour —
    # each DE profile gets its own MCP server registrations.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."Claude/claude_desktop_config.json" = {
      text = builtins.toJSON {
        mcpServers = {
          # ────────────────────────────────────────────────────────────────────
          # Placeholder — add MCP server entries here, e.g.:
          # ────────────────────────────────────────────────────────────────────
          #filesystem = {
          #  command = "npx";
          #  args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/<username>/Projects" ];
          #};
        };
      };
    };
  };
}
