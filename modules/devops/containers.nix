# modules/devops/containers.nix
#
# Docker and Podman solve the same problem differently.
# Docker uses a root daemon;, Podman is daemonless and rootless by default.
# In practice:
#  - Docker: better Compose ecosystem, more tutorials, most CI/CD defaults
#  - Podman: better security posture, OCI-native, systemd integration
# With both, you can experience the tradeoffs and choose per-project.
# podman's dockerCompat shim means `docker` commands transparently route to
# Podman when Docker daemon isn't running; you can test both with the same muscle memory.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.containers.enable) {
    # ─────────────────────────────────────────────────────────────────────────────
    # DOCKER
    # ─────────────────────────────────────────────────────────────────────────────
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true; # start the Docker daemon at boot.
      storageDriver = "btrfs"; # CypherOS leverages btrfs filesystem.

      # daemon.settings: docker daemon JSON config (equivalent to /etc/docker/daemon.json).
      # The docker daemon settings are pretty extensive
      # see also: https://github.com/NixOS/nixpkgs/issues/68349
      daemon.settings = {
        experimental = true;

        # journald integrates with `journalctl -u docker`; preferred over json-file on NixOS.
        # NOTE: If you prefer a JSON file instead:
        # log-driver = "json-file";
        # log-opts.max-size = "10m";
        # log-opts.max-file = "10";
        log-driver = "journald";

        # metrics-addr = "0.0.0.0:9323";
        # fixed-cidr-v6 = "fd00::/80";
        # ipv6 = true;
        # iptables = true;
        # ip6tables = false;
        registry-mirrors = [ "https://mirror.gcr.io" ];
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        # If you want to turn off the userland-proxy - designed for Windows.
        userland-proxy = false;

        # By default, the Docker daemon will store images, containers, and build context
        # on the root filesystem. To change the location that Docker stores its data,
        # configure a new data-root for the daemon by setting the data-root property
        data-root = "/home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/APPS/Docker/Docker_data";

        # Prune dangling images automatically. Not a daemon setting — do this
        # with a systemd timer or `docker system prune` manually.

        # default-address-pools = {
        #   base = "172.30.0.0/16";
        #   size = 24;
        # };
      };

      # Running Docker rootless (better security, especially at beginner and intermediate level):
      # This can be a way out of adding user to the docker group.
      # I.e, The docker group membership is effectively equivalent to being root!
      # rootless = {
      #   enable = true;
      #   setSocketVariable = true;
      # };
    };

    # add user to run commands without sudo (disabled; I am going for rootless docker for security).
    # the same can be achieved with:
    #   users.extraGroups.docker.members = [ "username-with-access-to-socket" ];
    users.users.cypher-whisperer.extraGroups = [
      "docker"
      "podman"
    ];

    # ─────────────────────────────────────────────────────────────────────────────
    # PODMAN
    # ─────────────────────────────────────────────────────────────────────────────
    virtualisation.podman = {
      enable = true;

      # dockerCompat: installs a `docker` → podman symlink so `docker` commands work
      # when the Docker daemon is not running. Disabled here because Docker is enabled
      # above; having both active creates ambiguity — the Docker socket wins by PATH
      # ordering, but the symlink still adds noise. Enable this and disable
      # virtualisation.docker if you decide to go Podman-only.
      dockerCompat = false;

      defaultNetwork.settings.dns_enabled = true;

      autoPrune = {
        enable = true;
        dates = "weekly"; # how often to prune. systemd calendar format: every Sunday at midnight.
        flags = [ "--all" ];
      };
    };

    environment.systemPackages = with pkgs; [

      # ── Docker ────────────────────────────────────────────────────────────────
      docker-client # CLI only — the daemon itself is an OS-level concern
      docker-compose # Manages multi-container apps defined in docker-compose.yml.(Docker + Podman)
      docker-compose-language-service # LSP server for docker-compose.yml files
      lazydocker # TUI dashboard for Docker containers

      # ── Podman ────────────────────────────────────────────────────────────────
      podman-compose # Drop-in for docker-compose when working rootlessly.
      podman-tui # TUI equivalent of lazydocker for Podman
      podman-desktop # Electron GUI; open-source Docker Desktop alternative
      pods # GNOME-native Podman GUI; integrates better with this DE

      # ── Image tooling ─────────────────────────────────────────────────────────
      skopeo # inspect/copy images across registries without pulling to disk
      buildah # build OCI images without a daemon; Podman-native `docker build` replacement
      dive # interactive layer explorer; essential for understanding image bloat
      trivy # CVE scanner for images, filesystems, and IaC
      cosign # Sigstore keyless image signing; supply-chain hygiene

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # wagoodman/whaler  # not in nixpkgs; similar to dive — revisit if packaged
    ];

  };
}
