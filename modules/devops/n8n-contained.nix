# =============================================================================
# CypherOS — DevOps :: n8n Workflow Automation (OCI Container)
# =============================================================================
# modules/cypher-os/devops/n8n.nix
#
# The nixpkgs n8n package has been broken on Hydra since 2022 because the npm network
# sandbox issue was never fully resolved in nixpkgs.
# Our option: run n8n as a Docker container via virtualisation.oci-containers
#  (sidesteps the Nix build entirely — this is how many NixOS users run n8n)
#
#
# ARCHITECTURE DECISION (2024-03):
#   The nixpkgs `pkgs.n8n` derivation has been broken on Hydra since 2022 due
#   to n8n's npm monorepo requiring network access during build — which Nix's
#   sandboxed build environment forbids. The last successful Hydra build was
#   n8n-0.168.1 (March 2022). Current nixpkgs ships n8n v2.x with no binary.
#
#   Resolution: run n8n via `virtualisation.oci-containers`, which pulls the
#   official Docker image from docker.n8n.io. The OCI image is built and
#   signed by n8n GmbH — no source build occurs on our machine.
#
# DATA PERSISTENCE:
#   Container data lives in /var/lib/n8n on the host, bind-mounted into the
#   container at /home/node/.n8n. This directory survives container recreation
#   and image upgrades. Back this up — it contains your workflows, credentials,
#   and (if not externally managed) your encryption key.
#
# NETWORKING:
#   n8n listens on 127.0.0.1:5678 — localhost only, not reachable from the
#   network. Caddy (or Traefik) terminates TLS and proxies to this port.
#   For local dev without a reverse proxy, change the port binding to
#   "5678:5678" to expose it directly on all interfaces.
#
# UPGRADING:
#   To upgrade n8n, change the image tag below, then run:
#     sudo nixos-rebuild switch
#   The new image is pulled automatically. If n8n introduces breaking changes
#   between major versions, check https://docs.n8n.io/release-notes/ first.
#   NEVER use `latest` for a production or data-bearing instance — you will
#   get surprise major version upgrades.
# =============================================================================

{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.n8n.enable) {
    # =========================================================================
    # Prerequisite: Docker daemon
    # =========================================================================
    # virtualisation.oci-containers with backend = "docker" requires Docker to
    # be running. This enables the Docker daemon as a system service.
    # All containers declared in this file run under this daemon.
    #
    # NOTE: If you prefer rootless containers (better security posture),
    # switch backend to "podman" and enable virtualisation.podman instead.
    # Podman is daemonless and rootless by default — better for a single-user
    # workstation like CypherOS. The tradeoff: podman has subtly different
    # networking behaviour (no host.docker.internal equivalent by default).
    # =========================================================================
    # NOTE: This is handled by ./containers.nix
    #
    #virtualisation.docker.enable = true;
    #virtualisation.podman.enable = true;

    # Add cypher_whisperer to the docker group so `docker` CLI works without sudo.
    # WARNING: membership in the docker group is effectively equivalent to root
    # access — anyone in this group can mount the host filesystem into a container.
    # On a single-user machine this is acceptable. On a multi-user machine, use
    # rootless podman instead.
    # =========================================================================
    # Also handled by ./containers.nix
    #
    # users.users.cypher_whisperer.extraGroups = [ "docker" ];

    # =========================================================================
    # Persistent data directory
    # =========================================================================
    # Create /var/lib/n8n on the host with correct ownership before the
    # container first starts. Without this, Docker creates the directory as
    # root, and n8n (which runs as UID 1000 "node" inside the container)
    # cannot write to it — the service fails silently.
    # =========================================================================
    systemd.tmpfiles.rules = [
      # "d" = create directory if absent, set mode and owner
      # 1000:1000 = UID/GID of the "node" user inside the n8n container
      "d /var/lib/n8n 0750 1000 1000 -"
    ];

    # =========================================================================
    # n8n OCI container
    # =========================================================================
    # Run n8n as an OCI container rather than a Nix derivation.
    # This bypasses the nixpkgs n8n package (which is broken on Hydra)
    # entirely. Docker images are fetched from Docker Hub — no Nix build.
    virtualisation.oci-containers.backend = "docker"; # or "podman" for rootless
    virtualisation.oci-containers.containers.n8n = {
      # -----------------------------------------------------------------------
      # Image
      # -----------------------------------------------------------------------
      # Pin to a major version tag (e.g. "2") rather than "latest".
      # This gives you automatic patch/minor updates within the major version
      # while preventing surprise breaking changes across major boundaries.
      #
      # To upgrade to the next major version: change "2" → "3" after reading
      # the n8n migration guide for that version.
      #
      # Official image: https://hub.docker.com/r/n8nio/n8n
      # -----------------------------------------------------------------------
      image = "docker.n8n.io/n8nio/n8n:2";

      # -----------------------------------------------------------------------
      # Port binding
      # -----------------------------------------------------------------------
      # "127.0.0.1:5678:5678" = bind only on loopback. n8n is not directly
      # reachable from the network — all external access goes through Caddy.
      # -----------------------------------------------------------------------
      ports = [ "127.0.0.1:5678:5678" ];

      # -----------------------------------------------------------------------
      # Volumes
      # -----------------------------------------------------------------------
      volumes = [
        # Host path : container path
        # /var/lib/n8n contains: database.sqlite, .n8n/config (encryption key),
        # workflow exports, and any files you save from workflows.
        "/var/lib/n8n:/home/node/.n8n"

        # Uncomment to expose a local directory to n8n for file-based workflows
        # (e.g., reading CSVs, writing outputs). Maps to /files inside the container.
        # "/var/lib/n8n/local-files:/files"
      ];

      # -----------------------------------------------------------------------
      # Environment variables
      # -----------------------------------------------------------------------
      # These mirror the environment block in your previous services.n8n config.
      # See https://docs.n8n.io/hosting/configuration/environment-variables/
      # for the full reference.
      # -----------------------------------------------------------------------
      environment = {
        #N8N_HOST = "localhost";

        # --- Networking ---
        N8N_PORT = "5678";
        N8N_LISTEN_ADDRESS = "0.0.0.0"; # Inside the container, listen on all
        # interfaces — the host-side port binding
        # above restricts external access.

        # The public URL n8n uses to build webhook URLs. Set this to your
        # Caddy-exposed domain. Without it, webhook URLs will contain
        # 127.0.0.1 which is useless for external triggers.
        # For local dev, leave as localhost. For production, use your domain:
        # WEBHOOK_URL = "https://n8n.yourdomain.com/";
        WEBHOOK_URL = "http://localhost:5678/";

        N8N_PROTOCOL = "http"; # http is correct — Caddy handles TLS termination

        # --- Timezone ---
        # Used by the Schedule/Cron trigger node.
        GENERIC_TIMEZONE = "Africa/Nairobi";
        TZ = "Africa/Nairobi";

        # --- Security ---
        # Enforce that n8n's settings.json has correct file permissions.
        # Prevents accidental world-readable credential exposure.
        N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";

        # Encryption key for stored credentials.
        # CRITICAL: Set this before first launch. If you start n8n without it,
        # n8n generates a random key and stores it in /var/lib/n8n/.n8n/config.
        # That is fine for development. For production, generate a key:
        #   openssl rand -hex 32
        # Then manage it with sops-nix and reference it as an environmentFile
        # (see the secrets section below).
        # N8N_ENCRYPTION_KEY = "your-key-here";  # ← NEVER do this
        # Use environmentFiles instead (see below).

        # --- Telemetry ---
        N8N_DIAGNOSTICS_ENABLED = "false";
        N8N_VERSION_NOTIFICATIONS_ENABLED = "false";

        # --- Runtime ---
        # Enable the task runner (sandboxed Code node execution).
        # The container image ships the runner binary, so this just enables it.
        N8N_RUNNERS_ENABLED = "true";
        NODE_ENV = "production";

        # --- Logging ---
        N8N_LOG_LEVEL = "info";
        N8N_LOG_OUTPUT = "console"; # journald picks this up: journalctl -u docker-n8n

        # =====================================================================
        # DATABASE (commented — SQLite default is fine for personal use)
        # =====================================================================
        # Uncomment to switch to PostgreSQL. Requires services.postgresql and
        # a database/user created. Use environmentFiles for the password.
        # DB_TYPE               = "postgresdb";
        # DB_POSTGRESDB_HOST    = "host.docker.internal"; # reach host postgres
        # DB_POSTGRESDB_PORT    = "5432";
        # DB_POSTGRESDB_DATABASE = "n8n";
        # DB_POSTGRESDB_USER    = "n8n";
        # DB_POSTGRESDB_PASSWORD = "";  # ← use environmentFiles, not inline

        # =====================================================================
        # EMAIL / SMTP (commented — enable when you have SMTP credentials)
        # =====================================================================
        # N8N_EMAIL_MODE  = "smtp";
        # N8N_SMTP_HOST   = "smtp.resend.com";
        # N8N_SMTP_PORT   = "587";
        # N8N_SMTP_USER   = "resend";
        # N8N_SMTP_PASS   = "";        # ← use environmentFiles
        # N8N_SMTP_SENDER = "n8n@pentara.tech";
        # N8N_SMTP_SSL    = "false";

        # =====================================================================
        # AUTHENTICATION (commented — owner account on first run is sufficient)
        # =====================================================================
        # N8N_BASIC_AUTH_ACTIVE   = "true";
        # N8N_BASIC_AUTH_USER     = "admin";
        # N8N_BASIC_AUTH_PASSWORD = "";  # ← use environmentFiles

      };

      # -----------------------------------------------------------------------
      # Secrets via environmentFiles
      # -----------------------------------------------------------------------
      # `environmentFiles` is the correct NixOS oci-containers pattern for secrets.
      # Each file is a plain KEY=VALUE file (same format as a .env file) that is
      # loaded at container start. These files must NOT be in the Nix store
      # (the store is world-readable). Manage them with sops-nix or agenix.
      #
      # Example file content (/run/secrets/n8n-env):
      #   N8N_ENCRYPTION_KEY=abc123...
      #   N8N_SMTP_PASS=hunter2
      #
      # Uncomment once you have sops-nix or agenix wired up:
      # environmentFiles = [ "/run/secrets/n8n-env" ];
      # -----------------------------------------------------------------------

      # -----------------------------------------------------------------------
      # Container lifecycle
      # -----------------------------------------------------------------------
      autoStart = true; # Start with the system; restart on failure

      # extraOptions passes additional flags directly to `docker run`.
      extraOptions = [
        # --restart is intentionally absent here.
        # The NixOS oci-containers module uses --rm on `docker run` so systemd
        # owns the container lifecycle. Docker's --restart and --rm are mutually
        # exclusive. Restart behaviour is declared at the systemd unit level instead.
        #"--restart=unless-stopped"  # Ensure the container restarts automatically if it crashes.
        #
        # Set a memory ceiling to prevent n8n from consuming all RAM on your
        # 8GB machine if a workflow goes haywire.
        "--memory=1g"
        "--memory-swap=1g" # Same as memory = no swap allowed beyond the limit
      ];
    }; # end containers.n8n

    # =========================================================================
    # Reverse proxy — Caddy (commented until you have a domain / need TLS)
    # =========================================================================
    # Caddy automatically provisions Let's Encrypt certificates. For local
    # dev (localhost only), leave this commented and access n8n at
    # http://localhost:5678 directly (you'll need to temporarily change the
    # port binding above to "5678:5678").
    #
    # When ready to expose over HTTPS:
    #   1. Point a DNS A record at this machine
    #   2. Uncomment this block
    #   3. Change WEBHOOK_URL above to "https://n8n.yourdomain.com/"
    #   4. Change the port binding back to "127.0.0.1:5678:5678"
    # -------------------------------------------------------------------------
    # services.caddy = {
    #   enable = true;
    #   virtualHosts."n8n.yourdomain.com" = {
    #     extraConfig = ''
    #       reverse_proxy localhost:5678
    #     '';
    #   };
    # };
    #
    # ── OR keep your Traefik setup ────────────────────────────────────────────
    # Your original compose.yaml used Traefik with ACME. If you want Traefik
    # instead of Caddy, you can run Traefik itself as an oci-container alongside
    # n8n. The Traefik container watches the Docker socket for labeled containers
    # and automatically creates routes. Add to containers.traefik:
    #
    # virtualisation.oci-containers.containers.traefik = {
    #   image = "traefik:v3";
    #   ports = [ "80:80" "443:443" ];
    #   volumes = [
    #     "/var/run/docker.sock:/var/run/docker.sock:ro"
    #     "/var/lib/traefik:/letsencrypt"
    #   ];
    #   cmd = [
    #     "--providers.docker=true"
    #     "--providers.docker.exposedbydefault=false"
    #     "--entrypoints.web.address=:80"
    #     "--entrypoints.websecure.address=:443"
    #     "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
    #     "--certificatesresolvers.letsencrypt.acme.email=your@email.com"
    #     "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    #   ];
    # };
    # Then add traefik labels to the n8n container via extraOptions:
    # extraOptions = [
    #   "--label=traefik.enable=true"
    #   "--label=traefik.http.routers.n8n.rule=Host(`n8n.yourdomain.com`)"
    #   "--label=traefik.http.routers.n8n.tls.certresolver=letsencrypt"
    #   "--label=traefik.http.routers.n8n.entrypoints=websecure"
    # ];

  };
}
