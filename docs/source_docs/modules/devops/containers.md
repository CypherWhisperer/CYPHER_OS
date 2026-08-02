# Containers — `containers.nix`

> Configures the Docker and Podman container runtimes as NixOS system services, and installs the full container toolchain: compose stacks, TUIs, image inspection, vulnerability scanning, and signing.

**Module path:** `modules/devops/containers.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Enable and configure the Docker daemon (`virtualisation.docker`)
- Enable and configure the Podman daemon (`virtualisation.podman`) with DNS and auto-pruning
- Add `cypher-whisperer` to the `docker` and `podman` groups
- Install Docker CLI, Docker Compose, Podman CLI tools, image inspection tools, and supply-chain security tools

**Does not:**

- Manage container images — those are ephemeral and never declared in Nix
- Manage Compose project files — those live in each project repository
- Declare or modify the `cypher-whisperer` user account — that stays in `configuration.nix`; this file only appends to `extraGroups`
- Run containers as OCI container services (`virtualisation.oci-containers`) — that pattern is used in `n8n-contained.nix` and `vault-contained.nix`

---

## Evaluation Context

| Property              | Value                                                             |
| --------------------- | ----------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                    |
| Options namespace     | `cypher-os.devops.containers.*`                                   |
| Imports `options.nix` | No — imported by `system.nix`                                     |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.containers.enable)` |
| Profile default       | `lib.mkDefault true` — enabled by default in the devops profile   |

---

## Block Analysis

---

### Block 1 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents all daemon configuration and package installation if either `devops.enable` or `devops.containers.enable` is false.

**Why is it here?** Standard CypherOS pattern. The parent (`devops`) and child (`containers`) flags compose: you can disable the entire devops subtree from the profile, or disable just containers within an otherwise-enabled devops setup.

---

### Block 2 — `virtualisation.docker`

**What is this?** NixOS `virtualisation.docker` module configuration.

**What does it do?** Starts the Docker daemon (`dockerd`) as a systemd service. Enables it at boot (`enableOnBoot = true`). Sets the log driver to `journald` so container logs flow into the systemd journal and are queryable with `journalctl -u docker` or in Grafana/Loki once the observability stack is active.

**Why is it here?** The Docker daemon is a system-level service — it runs as root and exposes a socket at `/var/run/docker.sock`. It cannot live in Home Manager. The CLI (`docker-client`) is installed as a package below; the separation is intentional: the daemon belongs to the OS layer, the CLI to the user environment layer.

The `log-driver = "journald"` choice: Docker's default is `json-file`, which writes per-container log files to `/var/lib/docker/containers/<id>/`. On NixOS, `journald` is preferable because it integrates with `journalctl`, avoids duplicate log storage, and automatically feeds into Promtail → Loki via the journal scraper in `observability.nix`.

`rootless` mode is not enabled here. Rootless Docker runs the daemon as the user rather than root, improving the security posture, but introduces constraints (no sub-1024 port binding, some network modes unavailable). The tradeoff is not worth it at the learning stage; revisit when the security model of container workloads becomes a deliberate concern.

```nix
virtualisation.docker = {
  enable       = true;
  enableOnBoot = true;
  daemon.settings."log-driver" = "journald";
};
```

---

### Block 3 — `users.users.cypher-whisperer.extraGroups`

**What is this?** A group membership extension for the primary user.

**What does it do?** Adds `cypher-whisperer` to the `docker` and `podman` groups. The `docker` group grants access to `/var/run/docker.sock` without `sudo`. The `podman` group is the rootless Podman socket group.

**Why is it here?** Without `docker` group membership, every `docker` command requires `sudo`, which breaks many tooling integrations (VS Code Docker extension, Lazydocker, `act`, Traefik's Docker provider). The security implication — `docker` group membership is effectively equivalent to root access — is acceptable on a single-user dev machine and is the standard NixOS pattern.

```nix
users.users.cypher-whisperer.extraGroups = [ "docker" "podman" ];
```

---

### Block 4 — `virtualisation.podman`

**What is this?** NixOS `virtualisation.podman` module configuration.

**What does it do?** Enables Podman. Sets `dockerCompat = false` (explicit, not the default). Enables container DNS resolution between containers in the default network. Configures weekly auto-pruning of all unused images, containers, and volumes.

**Why is it here?** Docker and Podman solve the same problem with different architectures. Docker uses a root daemon; Podman is daemonless and rootless by default; _Each `podman` invocation forks its own process. The virtualisation.podman module sets up the socket-activated service for tools that expect a Docker-style socket (like some GUIs)._ Having both during the learning phase lets you experience the tradeoffs firsthand.

`dockerCompat = false`: Podman's Docker compatibility shim installs a `docker` symlink pointing at `podman`. With the Docker daemon also running, this creates ambiguity — both `docker` and the shim coexist on PATH, and the behaviour depends on which socket is active. Setting it explicitly to `false` removes the ambiguity: `docker` always means Docker, `podman` always means Podman. If you decide to go Podman-only (disable `virtualisation.docker` above), flip this to `true`.

`defaultNetwork.settings.dns_enabled = true`: without this, containers in the default Podman network cannot resolve each other by name — only by IP address. Most Compose files use service names as hostnames; DNS must be on.

`autoPrune`: container images accumulate quickly during learning (every `docker pull`, every failed build). The weekly prune with `--all` removes all unused images, not just dangling ones. Remove the flag (_These are flags passed to `podman system prune`_)`--all` if you want to keep tagged images that aren't currently running.

```nix
virtualisation.podman = {
  enable       = true;
  dockerCompat = false;
  defaultNetwork.settings.dns_enabled = true;
  autoPrune = { enable = true; dates = "weekly"; flags = [ "--all" ]; };
};
```

---

### Block 5 — `environment.systemPackages`

**What is this?** The package list contributing to the system environment.

**What does it do?** Installs the Docker and Podman CLI stacks, image tooling, and supply-chain security tools. Packages are grouped by function with one-line inline comments naming the key use case.

**Why is it here?** These are user-facing CLI tools, not daemon components. They could theoretically live in Home Manager, but keeping the entire container stack in one NixOS module avoids split ownership — the daemon and its tooling are a unit.

#### Package inventory

**Docker stack:**
- `docker-client` — CLI only; the daemon is declared above as a service
- `docker-compose` — Compose v2 plugin/standalone binary; manages multi-container applications defined in `docker-compose.yml`; works with both Docker and Podman
- `docker-compose-language-service` — LSP server for `docker-compose.yml` files; provides completion and validation in Neovim and VSCode; requires editor LSP config to register it
- `lazydocker` — TUI dashboard showing containers, images, volumes, logs, and stats in a single terminal interface

**Podman stack:**
- `podman-compose` — Compose support for Podman; drop-in for `docker-compose` in rootless contexts; some edge-case Compose features differ
- `podman-tui` — Podman-native TUI equivalent of Lazydocker
- `podman-desktop` — Electron GUI; open-source Docker Desktop alternative
- `pods` — GNOME-native Podman GUI; integrates with the GNOME workflow better than `podman-desktop` on this DE

**Image tooling:**
- `skopeo` — inspect and copy container images across registries without pulling to disk; useful for checking manifests before pulling and copying images between registries
- `buildah` — build OCI-compliant images without a Docker daemon; the Podman-native `docker build` replacement; supports Dockerfile syntax and a native scripting API
- `dive` — interactive layer explorer; shows exactly which files each layer adds or modifies; essential for understanding image size and optimisation

**Supply-chain security:**
- `trivy` — CVE scanner for container images, filesystems, and IaC; scans OS packages and language dependencies; run before pushing any image
- `cosign` — Sigstore keyless image signing; becoming the standard for software supply-chain security

##### FIRST TIME SETUP:
```bash

# Podman rootless — no extra steps needed; works out of the box.
#  Docker socket — if you want Docker daemon (not just Podman compat):
systemctl start docker  # (or enable it via virtualisation.docker.rootless)
```

##### VERIFYING SETUP:
```bash

 docker run --rm hello-world
 podman run --rm hello-world
 docker compose version
 podman-compose --version
 dive --version
 trivy --version
```

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `virtualisation.docker.*`
- `virtualisation.podman.*`
- `users.users.cypher-whisperer.extraGroups`
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.docker-client`, `pkgs.docker-compose`, `pkgs.docker-compose-language-service`, `pkgs.lazydocker`
- `pkgs.podman-compose`, `pkgs.podman-tui`, `pkgs.podman-desktop`, `pkgs.pods`
- `pkgs.skopeo`, `pkgs.buildah`, `pkgs.dive`
- `pkgs.trivy`, `pkgs.cosign`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.containers.enable` | `bool` | `true` (profile default) | Starts Docker + Podman daemons; installs full toolchain |

---

## Design Notes

- The `docker` group grants effective root on this machine. This is the accepted tradeoff for a single-user dev workstation; document it explicitly if this host ever becomes multi-user.
- `podman-desktop` and `pods` overlap in function (both are Podman GUIs). `podman-desktop` is cross-platform Electron; `pods` is GNOME-native. Both are included because they serve different workflows: `podman-desktop` for registry browsing and full container management, `pods` for quick day-to-day use within the GNOME workflow.
- `docker-compose-language-service` has no effect until registered in the editor LSP config. It is installed here so the binary is available when the Neovim LSP config needs it, without requiring a rebuild at that point.

---

## Known Limitations

- Log rotation for `journald`-backed Docker logs is controlled by `journald.conf`, not by Docker itself. On a busy machine with many containers, Docker logs can fill the journal; set `SystemMaxUse` in `journald.conf` if this becomes an issue.
- `podman-desktop` is an Electron application and follows Electron's update cycle independently of nixpkgs. The nixpkgs version may lag behind upstream.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| OCI container usage | `./n8n-contained.nix`, `./vault-contained.nix` |
| Profile default     | `modules/profile/system.nix` |
