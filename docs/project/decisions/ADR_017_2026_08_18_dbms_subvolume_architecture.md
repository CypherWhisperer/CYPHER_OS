# ADR_017_2026_08_18: DBMS Subvolume Architecture

**Date:** 2026-08-18
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

Each DBMS in the stack needs somewhere durable to store its data — somewhere backup-able, snapshot-able, and independent of the OS/home-directory lifecycle during active tinkering. The system already runs Btrfs with a subvolume-per-concern layout *(`@nixos-root`, `@home`, `@nix-store`, `@swap`).*

A prior incident *(documented informally in `scripts/mount.sh` comments, see also journal)* established that mounting a subvolume _nested inside_ an already-mounted subvolume *(the original `@data` under `@home`)* is unsafe:
- systemd does not reliably guarantee mount ordering for that nesting pattern *(confirmed against [nixpkgs#217179](https://github.com/NixOS/nixpkgs/issues/217179), "systemd doesn't respect `fileSystems.<name>.depends`").*
- A failed/delayed mount silently falls back to the parent subvolume's own *(empty)* directory at that path — *data isn't lost, but appears to be.*

Separately, `services.postgresql.dataDir` / `services.mysql.dataDir` pointed at a non-default path lose systemd's automatic `StateDirectory=` provisioning *(directory creation, ownership, permissions)* and switch to `ReadWritePaths=`, which only grants access to a path that must already exist with correct ownership.

---

## Decision

Every DBMS gets its own **top-level Btrfs subvolume**, sibling to `@home`/`@nix-store`/`@swap` *(never nested inside another mounted subvolume),* following a fixed naming convention:

- Subvolume: `@dbms_<name>`
- Mountpoint: `/dbms/<name>`
- Covers: `postgres`, `mariadb`, `valkey`, `meilisearch`, `mongo`, `neo4j` *(TimescaleDB excluded — lives inside `/dbms/postgres` as a Postgres extension, not a separate service.)*

Ownership and permissions are declared via `systemd.tmpfiles.rules` *(`d /dbms/<name> 0700 <user> <group> - -`),* replacing what `StateDirectory=` would have handled automatically on the default path. `dataDir` *(Postgres/MariaDB)* points directly at the mountpoint.

---

## Reasoning

Top-level siblings sidestep the mount-ordering failure class entirely — *there's no nested mount unit whose ordering relative to a parent mount unit needs to be guaranteed, because nothing is nested.* This is a direct, deliberate response to the prior incident, not a coincidental layout choice.

`x-systemd.mkdir` is used on each `fileSystems` entry so the mountpoint directory is created automatically if missing — NixOS's fstab generator does not do this by default otherwise.

`systemd.tmpfiles.rules` is the declarative, idempotent replacement for what `StateDirectory=` provides on the default path — re-applied on every activation, living in the flake rather than being a manual one-time step that could be lost or drift.

---

## Alternatives Considered

### Leave `dataDir` at its default and back up `/var/lib/*` via the general system backup sweep

**Rejected:**
- The primary approach — while workable *(most backup tools don't care about subvolume boundaries),* it forfeits independent per-DBMS snapshotting, which was judged worth the modest one-time setup cost given the system's already-established subvolume-per-concern habit.

### Nest DBMS subvolumes under `@home` or `@data`

**Rejected:**
- outright — this is the exact pattern that caused the prior `@data` incident.

### Use `disko` to manage subvolume creation declaratively

Not adopted for this round — `disko` is a first-install tool, not an in-place migration tool for an already-installed system. Deferred to a dedicated future session **(see journal, [2026_08_18](../../development/journal/2026_08_18_dbms_stack_setup.md))** for the *next* fresh install.

---

## Consequences

**Positive:**

- Independent snapshot/backup domain per DBMS.
- Structurally immune to the mount-ordering failure class that caused the earlier `@data` incident.
- Consistent, predictable naming convention *(`@dbms_<name>` / `/dbms/<name>`)* that generalizes cleanly to future DBMSs *(see [RBK_007](../runbooks/RBK_007_adding_a_new_dbms_subvolume.md)).*

**Negative / Trade-offs:**

- Custom `dataDir` paths forfeit `StateDirectory=`'s automatic provisioning — ownership/permissions must be maintained declaratively via `tmpfiles.rules` rather than *"for free."*
- Accepted as a small, one-time-per-DB cost, not an ongoing operational burden.
- Six new top-level subvolumes add modest bookkeeping surface to the disk layout and to `scripts/create_dbms_subvolumes.sh`/`scripts/setup-disk.sh`.

**Neutral / Operational:**

- Retrofitting subvolumes onto an _already-installed_ system required a manual, imperative script *(`scripts/create_dbms_subvolumes.sh`)* rather than a purely declarative path — *this is expected given the current system predates the DBMS layer, not a gap in the declarative approach itself.*