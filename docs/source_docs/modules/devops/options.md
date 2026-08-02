# DevOps — `options.nix`

> _Declares every `cypher-os.devops.*` option consumed by the DevOps module's `system.nix`, making the option surface visible to both NixOS and Home Manager evaluation contexts._

**Module path:** `modules/devops/options.nix`
**Evaluation context:** `Both (options declaration)`
**Status:** `Stable`
**Last reviewed:** `2026-05-28`

---

## Responsibility

**Does:**

- Declares the entire `cypher-os.devops.*` option namespace using `lib.mkEnableOption`.
- Establishes the top-level `cypher-os.devops.enable` kill-switch that guards all DevOps subsystems.
- Defines granular per-subsystem and per-tool enable toggles (containers, kubernetes, databases, iac, secrets, n8n, cloud, observability, networking, cicd).
- Documents licensing or architectural constraints inline via the option description string (e.g., Terraform's BSL note; Vault's OCI containerisation note).

**Does not:**

- Configure any service, package, or Home Manager program — that is the responsibility of `system.nix` and any future `hm.nix`.
- Set defaults — profile-driven `lib.mkDefault` values live in `modules/profile/default.nix` (HM context) and `modules/profile/system.nix` (NixOS context).
- Import other files; this file is a leaf in the import graph.

---

## Evaluation Context

| Property              | Value                                                                          |
| --------------------- | ------------------------------------------------------------------------------ |
| Evaluated by          | `both` — imported by `system.nix` (NixOS context) and `default.nix` (HM context) |
| Options namespace     | `cypher-os.devops.[subsystem].[option]`                                        |
| Imports `options.nix` | Is `options.nix`                                                               |
| Kill-switch guard     | N/A — this file only declares; guards are applied in `system.nix` / `hm.nix`  |
| Profile default       | `lib.mkDefault [true \| false]` set in `modules/profile/[default\|system].nix` |

---

## Block Analysis

---

### Block 1 — Function signature

**What is this?** A standard NixOS/HM module function header — a lambda that receives the module system's arguments and returns an attribute set with a single `options` key.

**What does it do?** Binds `lib` from the module argument set so `lib.mkEnableOption` is in scope. The `...` absorbs all other module args (`config`, `pkgs`, `inputs`, etc.) that this file does not need.

**Why is it here?** Options-only files take no action on `config` and require no packages, so only `lib` is destructured. Keeping the argument set minimal makes it immediately legible that this file is a pure declaration — no side effects, no package references.

```nix
{ lib, ... }:
```

---

### Block 2 — Top-level enable option

**What is this?** A single `lib.mkEnableOption` declaration for `cypher-os.devops.enable`.

**What does it do?** Creates a `bool` option (default `false`) at `cypher-os.devops.enable`. When set to `true` (typically via `lib.mkDefault true` in a profile), it signals intent to activate DevOps infrastructure. All subsystem guards in `system.nix` are expected to AND this with their own enable flag.

**Why is it here?** The top-level toggle is the coarse kill-switch for the entire DevOps module. Having it as a single option means any host that does not set it gets no DevOps configuration at all — safe by default.

```nix
options.cypher-os.devops = {
  enable = lib.mkEnableOption "DevOps infrastructure";
  ...
};
```

---

### Block 3 — Container tooling options

**What is this?** A single `lib.mkEnableOption` nested under `containers`.

**What does it do?** Creates `cypher-os.devops.containers.enable` (bool, default `false`). When `true`, `system.nix` is expected to activate Docker, Podman with `dockerCompat`, `autoPrune`, and image inspection / scanning tools.

**Why is it here?** Containers are a distinct operational concern from Kubernetes orchestration. Separating the options allows a host to run Podman without k3s, or vice versa.

```nix
containers.enable = lib.mkEnableOption "container tooling (Docker, Podman, image inspection, scanning)";
```

---

### Block 4 — Kubernetes tooling options

**What is this?** A single `lib.mkEnableOption` nested under `kubernetes`.

**What does it do?** Creates `cypher-os.devops.kubernetes.enable` (bool, default `false`). When `true`, `system.nix` activates k3s (as a non-autostarting systemd service), kubectl, Helm, k3d, kind, and related cluster utilities.

**Why is it here?** Kubernetes tooling carries heavier system-level implications than containers (k3s registers a systemd service, modifies networking). Guarding it behind its own toggle prevents it from activating on hosts where only Docker/Podman is needed.

```nix
kubernetes.enable = lib.mkEnableOption "Kubernetes tooling (k3s, kubectl, Helm, k3d, kind, cluster utilities)";
```

---

### Block 5 — Database services options

**What is this?** A single `lib.mkEnableOption` nested under `databases`.

**What does it do?** Creates `cypher-os.devops.databases.enable` (bool, default `false`). When `true`, `system.nix` activates local dev database services — PostgreSQL 16, Redis, and SQLite tooling. MongoDB is excluded at the implementation level due to the SSPL license.

**Why is it here?** Local database services are stateful and consume ports; they should be opt-in per host. The description deliberately omits MongoDB to avoid implying it will be activated — that decision is documented in `system.nix` / `databases.nix`.

```nix
databases.enable = lib.mkEnableOption "local development database services (PostgreSQL, Redis, SQLite, MongoDB tools)";
```

---

### Block 6 — IaC options (two-level)

**What is this?** Two `lib.mkEnableOption` declarations forming a parent–child toggle pair under `iac`.

**What does it do?**
- `cypher-os.devops.iac.enable` — top-level gate for all IaC tooling (OpenTofu, Ansible, Pulumi, Terragrunt).
- `cypher-os.devops.iac.terraform.enable` — opt-in specifically for HashiCorp Terraform.

**Why is it here?** Terraform carries a BSL (Business Source License) that conflicts with the project's preference for open-source tooling. By placing it behind a separate child toggle, it can remain `false` by default while OpenTofu (the drop-in OSS fork) is activated via `iac.enable`. The description string itself documents the licensing concern, making it visible at the option declaration site without requiring a trip to `system.nix`.

```nix
iac.enable           = lib.mkEnableOption "Infrastructure as Code tooling (OpenTofu, Ansible, Pulumi, Terragrunt)";
iac.terraform.enable = lib.mkEnableOption "Terraform (HashiCorp BSL — prefer OpenTofu for new projects)";
```

---

### Block 7 — Secrets management options (two-level)

**What is this?** Two `lib.mkEnableOption` declarations forming a parent–child toggle pair under `secrets`.

**What does it do?**
- `cypher-os.devops.secrets.enable` — activates sops-nix, age, and gnupg.
- `cypher-os.devops.secrets.vault.enable` — opts in specifically to HashiCorp Vault, run as an OCI container.

**Why is it here?** Vault requires a running OCI container (via `virtualisation.oci-containers`) and a network-accessible port; it is heavier than sops/age and warrants independent control. The description documents the OCI deployment strategy, making the architectural decision visible at declaration time.

```nix
secrets.enable       = lib.mkEnableOption "secrets management tooling (sops-nix, age, Vault)";
secrets.vault.enable = lib.mkEnableOption "Vault (OCI-containerised)";
```

---

### Block 8 — n8n workflow automation option

**What is this?** A single `lib.mkEnableOption` for `n8n`.

**What does it do?** Creates `cypher-os.devops.n8n.enable` (bool, default `false`). When `true`, `system.nix` runs n8n as an OCI container (bypassing the broken/unfree nixpkgs derivation).

**Why is it here?** n8n sits outside every other subsystem category — it is a workflow automation platform, not infrastructure tooling. Giving it its own flat option rather than nesting it under e.g. `cicd` preserves semantic accuracy. The OCI deployment rationale is documented in the description string.

```nix
n8n.enable = lib.mkEnableOption "n8n workflow automation (OCI-containerised)";
```

---

### Block 9 — Cloud provider CLI options (three-level)

**What is this?** Four `lib.mkEnableOption` declarations forming a parent with three independent child toggles under `cloud`.

**What does it do?**
- `cypher-os.devops.cloud.enable` — parent gate.
- `cypher-os.devops.cloud.aws.enable` — AWS CLI v2 and AWS-ecosystem tools.
- `cypher-os.devops.cloud.azure.enable` — Azure CLI.
- `cypher-os.devops.cloud.gcp.enable` — Google Cloud SDK (gcloud, gsutil, bq).

**Why is it here?** Cloud provider CLIs are large, per-provider installs with no overlap. A host may target only AWS or only GCP; activating all three on every DevOps machine is wasteful. The three-child structure allows per-provider control while the parent toggle allows the entire cloud block to be disabled at once (e.g., on an air-gapped dev machine).

```nix
cloud.enable       = lib.mkEnableOption "cloud provider CLIs and supporting tooling";
cloud.aws.enable   = lib.mkEnableOption "AWS CLI v2 and AWS-ecosystem tools";
cloud.azure.enable = lib.mkEnableOption "Azure CLI";
cloud.gcp.enable   = lib.mkEnableOption "Google Cloud SDK (gcloud, gsutil, bq)";
```

---

### Block 10 — Observability stack options (three-level)

**What is this?** Four `lib.mkEnableOption` declarations forming a parent with three independent child toggles under `observability`.

**What does it do?**
- `cypher-os.devops.observability.enable` — parent gate for the local observability stack.
- `cypher-os.devops.observability.prometheus.enable` — Prometheus metrics collection and node-exporter.
- `cypher-os.devops.observability.grafana.enable` — Grafana dashboards.
- `cypher-os.devops.observability.loki.enable` — Loki log aggregation and Promtail log shipper.

**Why is it here?** Prometheus, Grafana, and Loki are often deployed together (the PLG stack) but can also run independently — Grafana can point at a remote Prometheus, or Loki can run without Grafana. Per-component toggles preserve that composability. The parent toggle lets the entire local observability stack be shut down without touching individual flags.

```nix
observability.enable            = lib.mkEnableOption "local observability stack (Prometheus, Grafana, Loki)";
observability.prometheus.enable = lib.mkEnableOption "Prometheus metrics collection and node exporter";
observability.grafana.enable    = lib.mkEnableOption "Grafana dashboards";
observability.loki.enable       = lib.mkEnableOption "Loki log aggregation and Promtail log shipper";
```

---

### Block 11 — Networking / reverse proxy options (two-level)

**What is this?** Three `lib.mkEnableOption` declarations forming a parent with two mutually exclusive (but not enforced) child toggles under `networking`.

**What does it do?**
- `cypher-os.devops.networking.enable` — parent gate for reverse proxy tooling.
- `cypher-os.devops.networking.caddy.enable` — Caddy web server / reverse proxy.
- `cypher-os.devops.networking.traefik.enable` — Traefik container-aware reverse proxy.

**Why is it here?** Caddy and Traefik serve overlapping but distinct use cases (Caddy for static/manual config; Traefik for dynamic container routing). Both may be declared but in practice only one should bind port 80/443 at a time — that constraint is an operational concern enforced at the `system.nix` level, not here.

```nix
networking.enable         = lib.mkEnableOption "reverse proxy and local networking tooling";
networking.caddy.enable   = lib.mkEnableOption "Caddy web server / reverse proxy";
networking.traefik.enable = lib.mkEnableOption "Traefik container-aware reverse proxy";
```

---

### Block 12 — CI/CD tooling option

**What is this?** A single `lib.mkEnableOption` for `cicd`.

**What does it do?** Creates `cypher-os.devops.cicd.enable` (bool, default `false`). When `true`, `system.nix` installs `act` (local GitHub Actions runner), `gh` (GitHub CLI), `actionlint` (Actions linter), and `github-runner`.

**Why is it here?** CI/CD tooling is developer-workstation-specific — it has no server-side service concerns and no port bindings. It is kept as a flat single toggle rather than further subdivided because the constituent tools are lightweight and almost always wanted together.

```nix
cicd.enable = lib.mkEnableOption "CI/CD tooling (act, gh, actionlint, github-runner)";
```

---

## Dependencies

**Imported files:**
- None — this file is a leaf; it imports nothing.

**NixOS options set by this file:** N/A — options declaration only.

**Home Manager options set by this file:** N/A — options declaration only.

**nixpkgs packages required:** None.

**External flake inputs used:** None.

---

## Option Surface

Every option declared in this file. All are `lib.mkEnableOption` — type `bool`, default `false`.

| Option | Type | Default | Semantic intent |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Top-level kill-switch for all DevOps infrastructure |
| `cypher-os.devops.containers.enable` | `bool` | `false` | Activate Docker, Podman (with dockerCompat), autoPrune, image tooling |
| `cypher-os.devops.kubernetes.enable` | `bool` | `false` | Activate k3s, kubectl, Helm, k3d, kind |
| `cypher-os.devops.databases.enable` | `bool` | `false` | Activate PostgreSQL 16, Redis, SQLite tooling |
| `cypher-os.devops.iac.enable` | `bool` | `false` | Activate OpenTofu, Ansible, Pulumi, Terragrunt |
| `cypher-os.devops.iac.terraform.enable` | `bool` | `false` | Opt in to HashiCorp Terraform (BSL — non-default) |
| `cypher-os.devops.secrets.enable` | `bool` | `false` | Activate sops-nix, age, gnupg |
| `cypher-os.devops.secrets.vault.enable` | `bool` | `false` | Run Vault as OCI container |
| `cypher-os.devops.n8n.enable` | `bool` | `false` | Run n8n as OCI container |
| `cypher-os.devops.cloud.enable` | `bool` | `false` | Parent gate for cloud provider CLIs |
| `cypher-os.devops.cloud.aws.enable` | `bool` | `false` | Install AWS CLI v2 and AWS-ecosystem tools |
| `cypher-os.devops.cloud.azure.enable` | `bool` | `false` | Install Azure CLI |
| `cypher-os.devops.cloud.gcp.enable` | `bool` | `false` | Install Google Cloud SDK (gcloud, gsutil, bq) |
| `cypher-os.devops.observability.enable` | `bool` | `false` | Parent gate for local observability stack |
| `cypher-os.devops.observability.prometheus.enable` | `bool` | `false` | Activate Prometheus and node-exporter |
| `cypher-os.devops.observability.grafana.enable` | `bool` | `false` | Activate Grafana dashboards |
| `cypher-os.devops.observability.loki.enable` | `bool` | `false` | Activate Loki and Promtail |
| `cypher-os.devops.networking.enable` | `bool` | `false` | Parent gate for reverse proxy tooling |
| `cypher-os.devops.networking.caddy.enable` | `bool` | `false` | Activate Caddy web server / reverse proxy |
| `cypher-os.devops.networking.traefik.enable` | `bool` | `false` | Activate Traefik container-aware reverse proxy |
| `cypher-os.devops.cicd.enable` | `bool` | `false` | Install act, gh, actionlint, github-runner |

---

## Comment Convention

Inline comments in source files use three header tiers to classify non-active code without explanation bloat. Deep rationale belongs here in the documentation, not in the source file.

```nix
# ── DEFERRED — not yet needed; low friction to add ───────────────────────────
# package-name  # reason: <one line>

# ── EXCLUDED — active decision not to include ────────────────────────────────
# package-name  # reason: BSL license / broken nixpkgs derivation / etc.

# ── PENDING — blocked on something external ──────────────────────────────────
# package-name  # blocked on: <what>
```

---

## Design Notes

- All toggles use `lib.mkEnableOption` with no explicit `default` — defaults to `false` implicitly. Opt-in posture is intentional: a new host gets zero DevOps configuration unless a profile or host config explicitly enables subsystems.
- The two-level and three-level parent–child toggle patterns (e.g., `cloud.enable` + `cloud.aws.enable`) follow a consistent convention: the parent is a coarse gate, children are fine-grained. `system.nix` guards each activation block with both levels ANDed.
- Architectural and licensing rationale is embedded directly in `mkEnableOption` description strings (`"Terraform (HashiCorp BSL…)"`, `"Vault (OCI-containerised)"`). This keeps the decision visible at the option declaration site — the first place a developer looks when deciding whether to enable something.
- `networking.caddy.enable` and `networking.traefik.enable` are not mutually exclusive at the option layer. Port-conflict prevention is an operational concern left to `system.nix`.
- MongoDB is absent from the `databases` option description despite being listed alongside other tools. The SSPL licensing exclusion is documented and enforced at the `system.nix` / `databases.nix` implementation level.

---

## Known Limitations

- No parent–child enforcement: enabling a child (e.g., `cloud.aws.enable`) when the parent (`cloud.enable`) is `false` produces no error — the guard in `system.nix` will simply be `false` on both, and the child flag is silently ignored. A `lib.mkAssert` or `config.warnings` entry in `system.nix` would catch this.
- `networking.caddy.enable` and `networking.traefik.enable` can both be `true` simultaneously; the port-conflict failure mode is not surfaced here.
- No option type other than `bool` is declared — any future need for e.g. configurable ports or versions will require a new option group in this file.
- Not yet validated on all five CypherOS lenses (Arch, Debian, Fedora, FreeBSD); only `cypher-nixos` is confirmed.

---

## Related

| Type                   | Reference                                    |
| ---------------------- | -------------------------------------------- |
| Options consumed by    | `./system.nix`                               |
| Counterpart file       | `./system.nix`                               |
| Entry point            | `./default.nix`                              |
| Profile default set in | `modules/profile/default.nix` · `modules/profile/system.nix` |
| ADR                    | _None yet_                                   |

---

<!-- METADATA
Module:   modules/devops/options.nix
Context:  Both (options declaration)
Hostname: cypher-nixos
Created:  2026-05-28
Updated:  2026-05-28
-->
