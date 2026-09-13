# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/mullvad.nix
# ──────────────────────────────────────────────────────────────────────────────
# ── PHILOSOPHY (READ BEFORE TOUCHING):
# ──────────────────────────────────────────────────────────────────────────────
# Mullvad Browser's entire privacy model depends on UNIFORMITY. Every user
# should look identical to trackers and fingerprinting probes.
#
# Any customisation — themes, extensions, changed settings, custom fonts —
# breaks this by making your browser instance distinguishable.
#
# THIS FILE IS INTENTIONALLY MINIMAL.
# No extensions. No settings overrides. No themes. No userChrome.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── USAGE PATTERN:
# ──────────────────────────────────────────────────────────────────────────────
# Paired with, say, Mullvad WireGuard VPN.
# The browser handles fingerprint layer; the VPN handles network/IP layer.
# Use Mullvad Browser for:
#   - Sensitive research you don't want linked to your identity.
#   - Financial information browsing.
#   - Sessions where fingerprint resistance matters more than convenience.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT MULLVAD BROWSER SHIPS BY DEFAULT:
# ──────────────────────────────────────────────────────────────────────────────
# - uBlock Origin (bundled, pre-configured)
# - NoScript
# - No sync, no telemetry, no crash reporting
# - Anti-fingerprinting defaults mirroring Tor Browser (without Tor network)
# - Window size bucketing to standard resolution
# - Uniform User-Agent string across all Mullvad Browser instances globally
#
# ──────────────────────────────────────────────────────────────────────────────
# ── CATPPUCCIN:
# ──────────────────────────────────────────────────────────────────────────────
# EXCLUDED — catppuccin/nix does not support Mullvad Browser, and applying
# any theme would break fingerprint uniformity. Intentionally not configured.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.mullvad.enable) {
    home.packages = with pkgs; [ mullvad-browser ];
  };
}
