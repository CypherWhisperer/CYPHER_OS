# Observability — `observability.nix`

> Declares the local observability stack: Prometheus (metrics), Grafana (dashboards), Loki (log storage), and Promtail (log shipping), all as NixOS system services with automatic Grafana data source provisioning.

**Module path:** `modules/devops/observability.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Configure `services.prometheus` with a node exporter and a self-scrape job
- Configure `services.grafana` with automatic Prometheus and Loki data source provisioning
- Configure `services.loki` with a local filesystem storage backend
- Configure `services.promtail` to ship the systemd journal into Loki
- Install `promtail` on PATH for manual pipeline testing

**Does not:**

- Manage Grafana dashboards declaratively (those are imported via the UI or provisioned separately in `services.grafana.provision.dashboards`)
- Configure alert routing — `prometheus-alertmanager` is DEFERRED
- Expose any port outside `127.0.0.1`

---

## Evaluation Context

| Property              | Value                                                                       |
| --------------------- | --------------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                              |
| Options namespace     | `cypher-os.devops.observability.*`                                          |
| Imports `options.nix` | No — imported by `system.nix`                                               |
| Kill-switch guard     | `lib.mkIf (top.enable && cfg.enable)` at top level; per-component `lib.mkIf` for each service |
| Profile default       | `lib.mkDefault false` — opt-in                                              |

---

## Block Analysis

---

### Block 1 — `let` bindings

**What is this?** Aliases for the two most-referenced option paths.

**What does it do?** Binds `cfg = config.cypher-os.devops.observability` and `top = config.cypher-os.devops`.

**Why is it here?** Four services each reference both paths in their `lib.mkIf` guards and in cross-service references (e.g. the Grafana provisioner reading `config.services.prometheus.port`). The aliases keep the guards readable.

---

### Block 2 — `services.prometheus`

**What is this?** NixOS `services.prometheus` module configuration.

**What does it do?** Starts a Prometheus server on port 9090 with a 15-second scrape interval. Enables the `node_exporter` on port 9100, which exposes host-level metrics (CPU, memory, disk, network). Declares a `node` scrape job that points at the node exporter. The web UI is available at `http://localhost:9090`.

**Why is it here?** Prometheus is the metrics foundation. Without it, Grafana has nothing to visualise. The node exporter is the entry point — before scraping application metrics you need to understand what host metrics look like. The `globalConfig` values (15s intervals) are standard defaults that balance freshness against disk I/O.

```nix
services.prometheus = lib.mkIf cfg.prometheus.enable {
  enable = true;
  port   = 9090;
  globalConfig = { scrape_interval = "15s"; evaluation_interval = "15s"; };
  exporters.node = { enable = true; port = 9100; enabledCollectors = [ ... ]; };
  scrapeConfigs = [{ job_name = "node"; ... }];
};
```

---

### Block 3 — `services.grafana`

**What is this?** NixOS `services.grafana` module configuration, including data source provisioning.

**What does it do?** Starts Grafana on `127.0.0.1:3001`. Port 3001 is chosen to avoid collision with common development servers on 3000. Disables telemetry reporting to `grafana.com`. Automatically provisions Prometheus and Loki as data sources on first start, conditioned on their respective enable flags.

**Why is it here?** Without provisioned data sources, every `nixos-rebuild switch` would require manual re-configuration through the Grafana UI. The `lib.optionals` on the data source list ensures a datasource is only provisioned if the backing service is actually enabled — preventing Grafana from displaying a broken data source connection.

```nix
services.grafana = lib.mkIf cfg.grafana.enable {
  settings.server = { http_addr = "127.0.0.1"; http_port = 3001; };
  settings.analytics.reporting_enabled = false;
  provision.datasources.settings.datasources =
    lib.optionals cfg.prometheus.enable [{ name = "Prometheus"; ... }]
    ++ lib.optionals cfg.loki.enable [{ name = "Loki"; ... }];
};
```

---

### Block 4 — `services.loki`

**What is this?** NixOS `services.loki` module configuration with an inline JSON config.

**What does it do?** Starts Loki on port 3100. Uses a local filesystem backend (BoltDB + filesystem object store) under `/var/lib/loki/`. Configures schema v13 with 24-hour index periods. Rejects log entries older than 7 days. Authentication is disabled (single-user local dev).

**Why is it here?** Loki provides the log aggregation that Grafana's log panel queries via LogQL. The filesystem backend avoids requiring an object store (S3, GCS) — intentional for a local lab. The config is written as an inline `pkgs.writeText` call rather than a separate file because it has no external dependencies and keeping it here preserves the single-file module pattern.

```nix
services.loki = lib.mkIf cfg.loki.enable {
  enable     = true;
  configFile = pkgs.writeText "loki-config.yaml" (builtins.toJSON { ... });
};
```

---

### Block 5 — `services.promtail`

**What is this?** NixOS `services.promtail` module configuration.

**What does it do?** Starts Promtail as a systemd service. Tails the systemd journal and forwards entries to Loki at `http://localhost:3100`. Attaches a `unit` label (derived from `__journal__systemd_unit`) so log lines are filterable by service in Grafana. Stores cursor positions in `/var/lib/promtail/positions.yaml` so it resumes from where it left off after a restart.

**Why is it here?** Promtail is the mandatory shipper that feeds Loki. Without it, Loki has no data. The journal scrape config is the most broadly useful starting point on NixOS — it captures logs from every systemd unit (Docker, k3s, PostgreSQL, etc.) without per-service configuration.

```nix
services.promtail = lib.mkIf cfg.loki.enable {
  enable = true;
  configuration = {
    clients = [{ url = "http://localhost:3100/loki/api/v1/push"; }];
    scrape_configs = [{ job_name = "journal"; journal = { ... }; }];
  };
};
```

---

### Block 6 — `environment.systemPackages`

**What is this?** A package list with `promtail` and DEFERRED comments.

**What does it do?** Ensures `promtail` is on PATH for manual pipeline testing and log pushing, independent of the systemd service. The DEFERRED block documents the extended observability stack (alertmanager, vector, OTEL collector, Jaeger) with one-line deferral reasons each.

**Why is it here?** The NixOS `services.promtail` module starts the daemon but does not guarantee the `promtail` binary is on PATH for the user. Adding it here closes that gap.

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `services.prometheus.*` — metrics collection
- `services.grafana.*` — dashboard server
- `services.loki.*` — log storage
- `services.promtail.*` — log shipping
- `environment.systemPackages` — `promtail` CLI

**nixpkgs packages required:**
- `pkgs.promtail`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.observability.enable` | `bool` | `false` | Activates this module |
| `cypher-os.devops.observability.prometheus.enable` | `bool` | `false` | Starts Prometheus + node exporter; provisions Grafana datasource |
| `cypher-os.devops.observability.grafana.enable` | `bool` | `false` | Starts Grafana on port 3001 |
| `cypher-os.devops.observability.loki.enable` | `bool` | `false` | Starts Loki + Promtail; provisions Grafana datasource |

---

## Port Map

| Service       | Port  | Bound to    |
|---------------|-------|-------------|
| Prometheus    | 9090  | `0.0.0.0`   |
| Node exporter | 9100  | `0.0.0.0`   |
| Grafana       | 3001  | `127.0.0.1` |
| Loki          | 3100  | `0.0.0.0`   |
| Promtail HTTP | 9080  | `0.0.0.0`   |

> Prometheus and Loki bind to all interfaces by default in their NixOS modules. On a single-user dev machine behind a firewall this is acceptable; tighten to `127.0.0.1` if exposed to a local network.

---

## Design Notes

- Grafana runs on port 3001 (not the default 3000) to avoid collision with Next.js and other common dev servers.
- The Loki config uses `builtins.toJSON` over a raw YAML string to get Nix-level type checking on the config structure. The tradeoff is that YAML comments are lost — acceptable here since the Nix source file is the authoritative documentation.
- Promtail is conditioned on `cfg.loki.enable`, not its own flag. There is no useful state for Loki-enabled + Promtail-disabled in a local dev setup; a separate `promtail.enable` flag would add option surface for no practical benefit.

---

## Known Limitations

- Prometheus binds to all interfaces (`0.0.0.0:9090`) by default. The NixOS module does not expose a `listenAddress` option at the top level — restrict via firewall rules if this is a concern.
- Loki's BoltDB-shipper backend is deprecated upstream in favour of TSDB. This is sufficient for a local learning lab but would need migration before any production-like use.
- Grafana's default admin credentials (`admin`/`admin`) are not changed by this module. Change them on first login.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| Profile default     | `modules/profile/system.nix` |
