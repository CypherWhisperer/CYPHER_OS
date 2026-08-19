# [2026_08_18] DBMS Stack Setup — Postgres, MariaDB, Valkey, and the Full Category Set

**Date:** 2026-08-18
**Duration:** ~4 sessions, spanning *2026-08-15* to *2026-08-18*
**Repos touched:** CypherOS
**Modules touched:**
1. `modules/devops/dbmss.nix` *(new.)*
2. `scripts/setup-disk.sh`
3. `scripts/mount.sh`
4. `scripts/create_dbms_subvolumes.sh` *(new.)*
**Phase:** Phase 2 — Infrastructure

---

## What I Worked On

Built out the full DBMS layer for CypherOS from scratch:
1. picked a concrete stack across all eight functional categories *(relational, cache, embedded, search, time-series, graph, document.)*
2. Designed and implemented the Btrfs disk layout to back it.
3. Wired up on-demand service lifecycle, and automated backups.

---

## What Got Done

- Locked in the stack:
    1. PostgreSQL *(primary.)*
    2. MariaDB over MySQL *(secondary/compat.)*
    3. Valkey over Redis *(cache.)*
    4. SQLite + DB Browser for SQLite *(embedded.)*
    5. Meilisearch over Elasticsearch/OpenSearch *(search.)*
    6. TimescaleDB over InfluxDB *(time-series, as a Postgres extension.)*
    7. Neo4j *(graph.)*
    8. MongoDB via `mongodb-ce` *(document.)*
       
- Deep-dived the full NixOS option surface for each — pulled directly from `nixpkgs` module source rather than trusting memory/other-LLM output at face value.

- Designed the subvolume architecture:
    - One top-level `@dbms_<name>` subvolume per DBMS.
    - sibling to `@home`/`@nix-store`/`@swap`
    - Deliberately never nested — a direct response to the earlier `@data`-under-`@home` incident, whose root cause turned out to be a real, documented NixOS issue *(systemd not reliably honoring nested mount ordering — nixpkgs#217179),* not the "non-deterministic Btrfs behavior" I'd originally assumed it was.
      
- Retrofitted six new subvolumes *(`postgres`, `mariadb`, `valkey`, `meilisearch`, `mongo`, `neo4j`)* onto the already-installed system via a one-time script, mounting the Btrfs top-level and creating them as siblings — ran clean, all six created, existing layout *(including a sprawling set of Docker-managed nested subvolumes under `@home`)* confirmed undisturbed.
  
- Wrote `modules/devops/dbmss.nix`:
    - Declarative mounts, `tmpfiles.rules`-based ownership *(replacing what `StateDirectory=` would've handled automatically on the default path),* 
    - Postgres fully configured (TimescaleDB/pgvector/PostGIS extensions, custom `pg_hba` auth, dev database + user), MariaDB configured with the password-auth-app-user caveat properly documented, Valkey as a purely ephemeral cache.
  
- Made Postgres/MariaDB/Valkey on-demand rather than always-on *(`wantedBy = lib.mkForce [ ]`)* — no current workload needs them running continuously.
  
- Automated daily `pg_dumpall`/`mariadb-dump` backups via `systemd.timer`, landing inside the directory I already manually mirror to an external HDD — *no new backup infrastructure introduced, just fed the existing habit better material.*

- Established Btrfs snapshots as a separate, complementary, explicit-for-now safety net — *distinct from the automated dumps, not a replacement for them.*
  
- Learned about `disko` — the actual answer to *"can Nix handle subvolume creation declaratively, not just mounting"* — and confirmed it gets remarkably close to the full from-ISO installation workflow I was imagining, with one important caveat:
    - **it's a first-install tool, not an in-place migration tool, so it doesn't help the _already-installed_ system, only the _next_ one.**

---

## Key Decisions Made

Formalized as ADRs this session — see `docs/project/decisions/ADR_016` through `ADR_020`:

- [ADR_016](../../project/decisions/ADR_016_2026_08_18_dbms_stack_selection.md) — DBMS stack selection
- [ADR_017](../../project/decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md) — DBMS subvolume architecture
- [ADR_018](../../project/decisions/ADR_018_2026_08_18_provisioning_dormant_dbms_subvolumes_ahead_of_need.md) — Provisioning dormant subvolumes ahead of need
- [ADR_019](../../project/decisions/ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md) — On-demand DBMS service lifecycle
- [ADR_020](../../project/decisions/ADR_020_2026_08_18_dbms_backup_strategy.md) — DBMS backup strategy

---

## Where I Got Stuck

The `@data` incident diagnosis from the original CypherOS install kept resurfacing as a source of caution — rightly so, but it took working through the actual systemd mount-ordering mechanics this session to understand _precisely_ what went wrong (nested subvolume mount ordering, not "subvolumes-within-subvolumes are inherently risky" as I'd generalized it to). That distinction mattered a lot for confidently designing the DBMS layout instead of just avoiding the pattern out of caution without understanding it.

Also spent real time on the Redis/Valkey `dataDir` question specifically because multiple sources (including earlier answers in this same session) gave inconsistent-sounding answers about whether it's settable — resolved by going to the actual module source rather than trusting any single account, including my own earlier one.

---

## What I Learned

- Systemd's `StateDirectory=` vs `ReadWritePaths=` distinction, and why a custom `dataDir` forfeits automatic provisioning — *and that `systemd.tmpfiles.rules` is the correct declarative replacement, not a workaround.*
  
- Root is not the unconditional "god mode" I assumed — Linux capabilities, mount namespaces, and seccomp all constrain even UID 0 in ways that have nothing to do with classic file-permission bits, and that's what systemd's service hardening *(`ProtectSystem`, `ReadWritePaths`, `systemCallFilter`)* actually leans on.
  
- Btrfs subvolume creation is a privileged filesystem operation, but subvolume _contents_ can be owned by anyone — the two are independent, which resolved my confusion about why `~/DATA` being user-owned was never actually inconsistent with anything.
  
- `disko` exists and is the real tool for the *"fully declarative disk layout from ISO"* workflow I was imagining — distinct from *(and complementary to)* NixOS's own `fileSystems`, which only ever handles mounting, never creation.
  
- Recursive `tmpfiles` ownership rules (`Z`) don't respect Btrfs subvolume boundaries the way they respect real mount points — *a real, sharp risk given Docker's nested subvolumes already living inside `@home`.*

---

## Open Questions

- Exact real option name for Meilisearch's data storage path — not confirmed this session; needs verification *(`nixos-option`/`search.nixos.org`)* before enabling it.
  
- Whether `backupRoot`'s eventual migration to a `${data_dir}`-relative path lands before or after the `@data` subvolume migration itself *(the two are coupled — see Next Session).*

---

## Next Session

Three follow-up threads, each explicitly deserving its own dedicated session rather than being squeezed into this one:

1. **Unifying "assumptions" via Nix options:**
    - Centralize hardcoded values currently scattered across `dbmss.nix` *(username, `/dev/sda1`, `backupRoot`, etc - and general CypherOS codebase into a single)* `cypher-os`-namespaced options file *(building on the `cypher-os.devops.*` pattern already in use),* so changing username/paths/disk device ripples out from one place.
       
2. **`~/DATA` → `@data` subvolume migration, and Docker data alongside it:**
    - Recreate `@data` as a top-level sibling subvolume *(now understood to be safe, unlike the original nested attempt),* symlink `~/DATA` to it. 
    - Separately:
        - Create a dedicated `@docker-data` subvolume for Docker's own storage-driver subvolumes, and — more importantly — establish an actual backup strategy for Docker's ***named volumes*** *(the real persistent app data),* explicitly distinct from the disposable, rebuildable image/container layer subvolumes, which should never be backed up directly.
       
3. **Scripting architecture overhaul + `disko` adoption:**
    - Unify `setup-disk.sh`/`mount.sh`/`create_dbms_subvolumes.sh` into a single `cypher-os` dispatcher script with git/npm-style subcommands.
    - Separately, write an actual `disko-config.nix` *(informed by this session's layout)* as the disk-provisioning path for the _next_ fresh install, given `disko` can't migrate the current already-installed system in place.

---

<!--
Commit range:
CypherOS: [short hash] → [short hash]
-->