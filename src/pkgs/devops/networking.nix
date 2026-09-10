# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/networking.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.devops;
in

{
  config = lib.mkIf (cfg.enable && cfg.networking.enable) {

    # ── Caddy ──────────────────────────────────────────────────────────────────
    # Modern web server and reverse proxy. Automatic HTTPS via Let's Encrypt,
    # readable Caddyfile syntax, and near-zero configuration for common patterns.
    # The best starting point for learning reverse proxying — the concepts
    # (virtual hosts, upstream proxying, TLS termination) transfer directly to
    # Nginx and Traefik once you know them here.
    #
    # The NixOS module manages the systemd service and the Caddy user.
    # Configure virtual hosts via services.caddy.virtualHosts in your host config
    # or by writing a Caddyfile to services.caddy.configFile.
    #
    # Admin API (for live config reload): http://localhost:2019
    # Metrics endpoint (Prometheus-compatible): http://localhost:2019/metrics
    services.caddy = lib.mkIf cfg.networking.caddy.enable {
      enable = true;

      # globalConfig: top-level Caddy global block. Equivalent to the `{ }` block
      # at the top of a Caddyfile. These settings apply to the entire server.
      globalConfig = ''
        # Disable the default HTTPS redirect for local dev — avoids certificate
        # warnings when you access plain http:// endpoints locally.
        # Remove in production.
        auto_https off
      '';

      # Example virtual host (commented out — uncomment and adapt per project):
      # virtualHosts."app.localhost" = {
      #   extraConfig = ''
      #     reverse_proxy localhost:3000
      #   '';
      # };
    };

    # ── Traefik ────────────────────────────────────────────────────────────────
    # Container-aware reverse proxy and load balancer. Watches Docker and
    # Kubernetes for running containers and automatically configures routing
    # based on container labels — no manual config file updates needed when
    # services start or stop. The canonical ingress controller for local
    # Docker Compose and k3s setups.
    #
    # Dashboard: http://localhost:8080 (when insecure API is enabled below)
    services.traefik = lib.mkIf cfg.networking.traefik.enable {
      enable = true;

      staticConfigOptions = {
        # api.insecure: expose the Traefik dashboard without authentication.
        # Fine for local dev; disable in any environment reachable from a network.
        api.insecure = true;

        entryPoints = {
          web.address = ":80";
          websecure.address = ":443";
        };

        # providers.docker: enable Docker provider — Traefik watches the Docker
        # socket for containers with `traefik.*` labels and auto-configures routes.
        providers.docker = {
          exposedByDefault = false; # only route containers that explicitly opt in
        };
      };
    };

    # Traefik needs access to the Docker socket to discover containers.
    users.users.traefik.extraGroups = lib.mkIf cfg.networking.traefik.enable [ "docker" ];

    environment.systemPackages = with pkgs; [

      # ── mkcert ────────────────────────────────────────────────────────────────
      # Generates locally-trusted TLS certificates for development. Creates a local
      # CA, installs it into the system trust store and browser stores, then issues
      # certificates for any hostname you specify (including *.localhost).
      # Run once: mkcert -install
      # Then per-project: mkcert app.localhost 127.0.0.1
      # Certificates are trusted by Chrome, Firefox, and curl without warnings —
      # essential for testing HTTPS flows locally.
      mkcert

      # ── DEFERRED — networking tools ───────────────────────────────────────────
      # nginx          # when you need to study Nginx config syntax directly;
      #                # Caddy covers learning needs for now
      # haproxy        # high-performance TCP/HTTP load balancer; production-grade
      #                # deferred: add when studying advanced load balancing
      # cloudflared    # Cloudflare Tunnel — expose local services publicly without
      #                # port forwarding; deferred until cloud work begins
    ];

  };
}
