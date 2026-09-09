# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/tor_system.nix
# ──────────────────────────────────────────────────────────────────────────────
# Tor Daemon module for CypherOS.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.tor.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # SYS-LEVEL TOR DAEMON (optional but recommended).
    # ──────────────────────────────────────────────────────────────────────────
    # Enabling this provides:
    #   - Persistent tor circuits across Tor Browser launches
    #
    #   - A SOCKS5 proxy at 127.0.0.1:9050 usable by other tools:
    #       torsocks curl https://check.torproject.org/api/ip
    #
    #       ssh \
    #       -o ProxyCommand='ncat  \
    #       --proxy 127.0.0.1:9050 \
    #       --proxy-type socks5 %h %p' user@host.onion
    #
    #   - tor control port at 127.0.0.1:9051 for advanced circuit management
    #
    # Specific use case (OnionShare, torsocks, etc.)
    # ──────────────────────────────────────────────────────────────────────────
    services.tor = {
      enable = true;
      client.enable = true; # SOCKS5 proxy at :9050
      settings = {
        # ──────────────────────────────────────────────────────────────────────
        # Increase guard node rotation time (reduces correlation window)
        # ──────────────────────────────────────────────────────────────────────
        GuardLifetime = "60 days";

        # ──────────────────────────────────────────────────────────────────────
        # Enforce only high-bandwidth, stable exit nodes
        # optional; restrict exit jurisdictions
        # ──────────────────────────────────────────────────────────────────────
        ExitNodes = "{us},{de},{nl},{ch}";

        # ──────────────────────────────────────────────────────────────────────
        # Stream isolation: separate circuit per destination
        # ──────────────────────────────────────────────────────────────────────
        IsolateDestAddr = 1;
        IsolateDestPort = 1;
      };
    };
  };
}
