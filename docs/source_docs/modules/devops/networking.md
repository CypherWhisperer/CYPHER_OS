# Networking — `networking.nix`

> Configures local reverse proxy and networking tooling: Caddy (simple dev proxy), Traefik (container-aware ingress), and `mkcert` (locally-trusted TLS certificates).

**Module path:** `modules/devops/networking.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Start `services.caddy` with HTTPS auto-promotion disabled for local dev, when `networking.caddy.enable` is true
- Start `services.traefik` with Docker provider and an insecure dashboard, when `networking.traefik.enable` is true
- Add the `traefik` system user to the `docker` group so Traefik can watch the Docker socket
- Install `mkcert` for locally-trusted TLS certificate generation

**Does not:**

- Declare virtual hosts or Traefik routes declaratively — those belong in per-project or per-host configuration
- Manage TLS certificate files — `mkcert` generates them on demand; they are never stored in the Nix store
- Install or configure Nginx — DEFERRED; Caddy covers the learning surface

---

## Evaluation Context

| Property              | Value                                                          |
| --------------------- | -------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                 |
| Options namespace     | `cypher-os.devops.networking.*`                                |
| Imports `options.nix` | No — imported by `system.nix`                                  |
| Kill-switch guard     | `lib.mkIf (top.enable && cfg.enable)`                          |
| Profile default       | `lib.mkDefault false` — opt-in                                 |

---

## Block Analysis

---

### Block 1 — `let` bindings

**What is this?** Aliases for the two most-referenced option paths.

**What does it do?** Binds `cfg = config.cypher-os.devops.networking` and `top = config.cypher-os.devops`.

**Why is it here?** Same rationale as `cloud.nix` — two sub-flags (`caddy`, `traefik`) each need both paths in their guards; aliases reduce noise.

---

### Block 2 — `services.caddy`

**What is this?** NixOS `services.caddy` module configuration.

**What does it do?** Starts the Caddy web server and reverse proxy. The `globalConfig` block sets `auto_https off` — Caddy would otherwise redirect all HTTP to HTTPS automatically, which breaks local dev flows that use plain `http://localhost` addresses. Virtual hosts are not declared here; they are added per-project in the host configuration or via `services.caddy.virtualHosts`.

**Why is it here?** Caddy is the recommended starting point for learning reverse proxying: automatic HTTPS, a readable Caddyfile syntax, and minimal boilerplate. The admin API at `localhost:2019` also exposes a Prometheus-compatible `/metrics` endpoint, which plugs directly into the observability module.

```nix
services.caddy = lib.mkIf cfg.caddy.enable {
  enable = true;
  globalConfig = ''
    auto_https off
  '';
};
```

---

### Block 3 — `services.traefik`

**What is this?** NixOS `services.traefik` module configuration.

**What does it do?** Starts Traefik with two entry points (`web` on 80, `websecure` on 443) and the Docker provider enabled. The Docker provider watches `/var/run/docker.sock` for containers with `traefik.*` labels and auto-configures routes. `exposedByDefault = false` means containers must opt in with a `traefik.enable=true` label. The dashboard at `localhost:8080` is enabled without authentication.

**Why is it here?** Traefik is the natural complement to Caddy in a container environment — where Caddy excels at manually-declared static routes, Traefik excels at dynamic routing from container labels. Both belong here because they represent different routing paradigms you will encounter in real DevOps work.

```nix
services.traefik = lib.mkIf cfg.traefik.enable {
  enable = true;
  staticConfigOptions = {
    api.insecure = true;
    entryPoints   = { web.address = ":80"; websecure.address = ":443"; };
    providers.docker.exposedByDefault = false;
  };
};
```

---

### Block 4 — Traefik Docker group membership

**What is this?** A `users.users.traefik.extraGroups` assignment conditioned on Traefik being enabled.

**What does it do?** Adds the `traefik` system user (created by the NixOS Traefik module) to the `docker` group, granting it read access to `/var/run/docker.sock`.

**Why is it here?** Without Docker socket access, Traefik's Docker provider cannot discover running containers and no routes are configured. The Traefik service starts but does nothing useful. This is the minimal permission needed; mounting the socket read-only would be more secure but is not directly supported by the NixOS service definition.

```nix
users.users.traefik.extraGroups = lib.mkIf cfg.traefik.enable [ "docker" ];
```

---

### Block 5 — `environment.systemPackages`

**What is this?** Package list with `mkcert` and DEFERRED comments.

**What does it do?** Installs `mkcert` on PATH. Documents Nginx, HAProxy, and `cloudflared` as DEFERRED with one-line deferral reasons each.

**Why is it here?** `mkcert` is a networking concern — it generates TLS certificates for local dev. It was previously misclassified in `secrets.nix`; TLS certificates are not application secrets — they are transport layer infrastructure. Moving it here aligns it with the reverse proxy tooling that consumes the certificates.

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `services.caddy.*`
- `services.traefik.*`
- `users.users.traefik.extraGroups`
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.mkcert`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.networking.enable` | `bool` | `false` | Activates this module |
| `cypher-os.devops.networking.caddy.enable` | `bool` | `false` | Starts Caddy service |
| `cypher-os.devops.networking.traefik.enable` | `bool` | `false` | Starts Traefik service; adds traefik user to docker group |

---

## Design Notes

- `mkcert` is unconditional within the module guard (not gated on Caddy or Traefik) because it is useful regardless of which proxy is running — any local HTTPS development needs it.
- Traefik's `api.insecure = true` is intentional for a single-user dev machine. In any multi-user or network-exposed environment this must be replaced with proper authentication middleware.
- Both Caddy and Traefik can be enabled simultaneously without conflict — they bind to different management ports (2019 vs 8080) and can serve different hostnames on 80/443 via their respective routing configurations.

---

## Known Limitations

- Traefik's Docker provider requires the Docker daemon to be running. If `cypher-os.devops.containers.enable` is false, the Docker socket may not exist, and Traefik will log errors on startup.
- Caddy virtual hosts must be added manually per-project in the host configuration. There is no declarative CypherOS convention for this yet.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| Profile default     | `modules/profile/system.nix` |
| `mkcert` moved from | `./secrets.nix`              |
