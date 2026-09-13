# ──────────────────────────────────────────────────────────────────────────────
# modules/apps/browser/tor-hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Tor Browser module for CypherOS.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── THREAT MODEL CONTEXT:
# ──────────────────────────────────────────────────────────────────────────────
# Tor Browser is NOT a daily driver. It is a precision instrument for cases
# where dissociating your real identity from your network traffic is the
# primary goal. Use it when:
#   - Accessing .onion services
#   - Communicating with sources where IP exposure is unacceptable
#   - Operating under a threat model where your ISP, Cloudflare, or a
#     national network observer is an adversary
#
#   - You need plausible deniability about which site you accessed
#
# Use Mullvad Browser for everyday sensitive browsing.
# Use Tor Browser only when anonymity is the mission-critical requirement.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── HOW TOR BROWSER ACHIEVES ANONYMITY:
# ──────────────────────────────────────────────────────────────────────────────
# 1. Circuit routing: traffic exits through 3 hops (Guard → Middle → Exit).
#    No single node knows both source and destination.
#
# 2. Fingerprint uniformity: identical UA, window size, fonts, canvas noise
#    across all Tor Browser users — same model as Mullvad Browser.
#
# 3. No persistent state: cookies, cache, history cleared per-session.
# 4. JavaScript sandboxed via NoScript (configurable per-security-level).
#
# ──────────────────────────────────────────────────────────────────────────────
# ── SECURITY LEVELS:
# ──────────────────────────────────────────────────────────────────────────────
# Standard  → JS enabled everywhere. Same as normal browsing. Weakest.
# Safer     → JS disabled on non-HTTPS sites. Some media disabled.
# Safest    → JS disabled EVERYWHERE. Only essential HTML/CSS loads.
#             Breaks most of the clearnet. Correct for high-stakes sessions.
#
# The security level is set in-browser via the Shield icon → Change...
# It CANNOT be set declaratively in NixOS — Tor Browser manages it in its
# own profile directory which is outside our control by design.
# When launching for a sensitive session: always check the level first.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── WHAT THIS MODULE DOES:
# ──────────────────────────────────────────────────────────────────────────────
# Installs tor-browser from nixpkgs (the official Tor Project build,
# verified with upstream signatures in nixpkgs). Enables the tor daemon
# as a systemd service for circuit reuse across sessions if desired.
#
# NixOS ships `tor-browser` (the browser bundle) and `tor` (the daemon)
# as separate packages. The browser bundle includes its own tor binary
# for standalone use — the system tor daemon is optional but provides
# persistent circuits and can be shared with other tor-aware tools
# (e.g. torsocks, OnionShare, Ricochet-Refresh).
#
# ──────────────────────────────────────────────────────────────────────────────
# ── OPERATIONAL SECURITY NOTES:
# ──────────────────────────────────────────────────────────────────────────────
#   These are not Nix concerns — they are human behaviour concerns:
#
#   1. Never maximise the Tor Browser window. Tor normalises window sizes
#      to buckets; maximising reveals your real screen resolution.
#
#   2. Never install additional extensions. One extra extension =
#      unique fingerprint.
#
#   3. Never log into personal accounts (Google, email, social) while on Tor.
#      The moment you log in, anonymity is gone regardless of the network layer.
#
#   4. Never torrent over Tor. Torrents bypass SOCKS proxy and leak real IP.
#
#   5. Never open documents (PDF, DOCX) downloaded over Tor in external apps
#      while connected — they may call home via non-Tor network paths.
#
#   6. Be aware of timing correlation attacks: a global adversary watching
#      both your guard node traffic and the exit can correlate sessions
#      even without decrypting them. This is Tor's known unsolved problem.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── CATPPUCCIN:
# ──────────────────────────────────────────────────────────────────────────────
# EXCLUDED — same reasoning as Mullvad Browser. Theming = unique fingerprint.
# catppuccin/nix does not support tor-browser and should never be applied.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── VERIFYING THE PACKAGE:
# ──────────────────────────────────────────────────────────────────────────────
# nixpkgs ships the official Tor Project build with upstream signature
# verification during the build phase.
#
# Confirm the package hash and source against:
#   https://www.torproject.org/download/
#
#   nix eval --raw nixpkgs#tor-browser.src.url
#   nix eval --raw nixpkgs#tor-browser.version
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

  config = lib.mkIf (cfg.enable && cfg.tor.enable) {
    home.packages = with pkgs; [ tor-browser ];
  };
}
