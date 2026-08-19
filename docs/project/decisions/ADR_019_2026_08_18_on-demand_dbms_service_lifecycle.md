# ADR_019_2026_08_18: On-Demand DBMS Service Lifecycle

**Date:** 2026-08-18
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

None of Postgres, MariaDB, or Valkey currently back a persistent, always-on workload on this machine — *they're used during active development sessions, not continuously.*

NixOS modules for these services default to starting automatically at boot *(`wantedBy = [ "multi-user.target" ]` under the hood)* once `enable = true`.

---

## Decision

Postgres, MariaDB, and the default Valkey instance are fully configured *(`enable = true`, `dataDir`, extensions, `ensureDatabases`/`ensureUsers` all wired up)* but do **not** start automatically at boot.

Each service's `wantedBy` is overridden to an empty list *(`wantedBy = lib.mkForce [ ];`),* leaving the unit installed and manually startable *(`systemctl start postgresql` / `mysql` / `redis-`.)*

---

## Reasoning

There is currently no persistent case requiring any of these to be running continuously — *starting them on demand during a dev session avoids idle compute/memory overhead for services that would otherwise sit unused most of the time.*

`wantedBy = lib.mkForce [ ]` is the minimal override that achieves this:
- the unit is still fully declared *(config generation, `ensureDatabases`/`ensureUsers`/`initdb` logic all present and correct),* it simply isn't pulled in by `multi-user.target` at boot.

---

## Alternatives Considered

### Leave services always-on *(module defaults)*

**Rejected:**
- No current workload needs continuous availability — pure overhead for this machine's actual usage pattern.

### `enable = false` and start manually via raw commands *(`pg_ctl`, etc.),* bypassing the NixOS module entirely

**Rejected:**
- This would forfeit all the module's declarative machinery *(`dataDir` wiring, `ensureDatabases`/`ensureUsers`, config generation, systemd hardening)* for no benefit over the `wantedBy` override, which keeps all of that while still avoiding auto-start.

---

## Consequences

**Positive:**

- No idle compute/memory cost from unused always-on daemons.
- Full declarative configuration *(schema/user bootstrapping, extensions, tuning)* still applies the moment the service is manually started — nothing is deferred or degraded by being on-demand.

**Negative / Trade-offs:**

- Any workflow assuming these services are always reachable *(e.g. an app expecting Postgres on `localhost:5432` without prompting)* needs an explicit `systemctl start` step first — *a manual habit to build.*
- Unattended/automated backup timers ([ADR_020](ADR_020_2026_08_18_dbms_backup_strategy.md)) must explicitly wake the relevant service *(`wants`/`after` in the backup unit)* since it can't assume the DB is already running — this is the one deliberate exception carved into the *"purely on-demand"* posture.

**Neutral / Operational:**

- See [RBK_005](../runbooks/RBK_005_dbms_service_lifecycle.md) for day-to-day start/stop/status procedure.