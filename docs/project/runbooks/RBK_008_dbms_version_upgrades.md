# Runbook: DBMS Version Upgrades

**Last verified:** 2026-08-18
**Host:** `cypher-nixos`
**Module:** `modules/devops/dbmss.nix`
**Trigger:** Reactive — *a deliberate decision to bump a pinned DBMS package version.*
**Estimated time:**
1. ~30–60 minutes *(Postgres.)*
2. ~15–30 minutes *(MariaDB.)*
3. <5 minutes *(Valkey.)*

_Applies to PostgreSQL, MariaDB, and Valkey — the three pinned, actively-running DBMSs. Not applicable to SQLite (file format has been stable and forward/backward-compatible across essentially all versions — a version bump there is a non-event). Extend this runbook once Meilisearch/MongoDB/Neo4j move from dormant to active (see RBK_006)._

---

## When To Use This Runbook

Any time you're changing `package = pkgs.postgresql_{version};` *(or the MariaDB/Valkey equivalent)* in `modules/devops/dbmss.nix` to a newer version — never bump these opportunistically as a side effect of an unrelated `nixpkgs` update; treat it as its own deliberate action.

---

## Prerequisites

- A fresh, verified backup exists *(run [RBK_004](RBK_004_dbms_data_backup_and_restore.md) Procedure B manually first — don't rely on the daily timer's last run).*
  
- A Btrfs snapshot of the relevant `/dbms/<name>` subvolume, taken immediately before starting *([RBK_004](RBK_004_dbms_data_backup_and_restore.md) Procedure A)* — this is your fast rollback if the upgrade goes wrong.
  
- Read the target version's release notes for breaking changes, specifically around extensions in use *(`timescaledb`, `pgvector`, `postgis` for Postgres).*

---

## Procedure A: PostgreSQL Major Version Bump *(dump/restore method)*

This is the simpler, safer default given we already have automated `pg_dumpall` output — *prefer it over `pg_upgrade` unless dataset size makes dump/restore impractically slow.*

### Step 1: Take a fresh dump against the _current_ version

```bash
sudo systemctl start postgresql
sudo -u postgres pg_dumpall | gzip > /tmp/pre-upgrade-dump.sql.gz
sudo systemctl stop postgresql
```

### Step 2: Snapshot the current dataDir (belt-and-suspenders alongside the dump)

```bash

sudo btrfs subvolume snapshot -r /dbms/postgres /dbms/.snapshots/postgres_pre_upgrade_$(date +%Y%m%d)
```

### Step 3: Update the package pin and extensions in `dbmss.nix`

```nix
services.postgresql = {
  package = pkgs.postgresql_19;  # bumped
  extensions = ps: with ps; [ timescaledb pgvector postgis ];  # confirm each has a postgresql_19 build
  # ...
};
```

**Expected result:** `nix flake check` *(or a dry rebuild)* succeeds — a missing extension build for the new major version will surface here as an evaluation error, before touching the live system.

### Step 4: Point `dataDir` at a fresh location for the new version

A new major version needs a fresh, empty `dataDir` to initialize into — *don't point it at the old one.*

```nix

dataDir = "/dbms/postgres_{version}";  # temporary, new subvolume or subdirectory for the new version
```

(If using a genuinely new location, follow [RBK_007](RBK_007_adding_a_new_dbms_subvolume.md) first to provision it properly rather than improvising a bare directory.)

### Step 5: Rebuild and start against the fresh dataDir

```bash
sudo nixos-rebuild switch --flake .#cypher-nixos
sudo systemctl start postgresql
```

**Expected result:** `initdb` runs cleanly against the empty new `dataDir`, service comes up.

### Step 6: Restore the dump into the new version

```bash
gunzip -c /tmp/pre-upgrade-dump.sql.gz | sudo -u postgres psql
```

### Step 7: Verify, then update extensions

```sql
-- as the postgres user, per database using timescaledb/pgvector/postgis:
ALTER EXTENSION timescaledb UPDATE;
ALTER EXTENSION postgis UPDATE;
```

**Expected result:** no errors; `\dx` shows the new extension version.

### Step 8: Once confident, retire the old dataDir and rename

Rename `dataDir` back to `/dbms/postgres` *(update the Nix config, rebuild)* once satisfied the new version is solid — don't leave a permanent `postgres_{version}`-style name lying around once the migration is done.

---

## Procedure B: MariaDB Version Bump

### Step 1: Backup and snapshot *(same pattern as Procedure A, Steps 1–2, using `mariadb-dump --all-databases`)*

### Step 2: Update the package pin

```nix
services.mysql.package = pkgs.mariadb_1110;  # bumped
```

### Step 3: Rebuild and run `mariadb-upgrade`

```bash
sudo nixos-rebuild switch --flake .#cypher-nixos
sudo systemctl start mysql
sudo mariadb-upgrade
```

**Expected output:**
- A list of tables checked, no `ERROR` lines.

**If this fails:**
- Restore from the pre-upgrade dump *(same restore pattern as Procedure A, Step 6, using `mysql` instead of `psql`).*

---

## Procedure C: Valkey Version Bump

### Step 1: Update the package pin

```nix

services.redis.package = pkgs.valkey;  # nixpkgs' current version is picked up automatically on the next channel bump; pin more specifically only if you need to hold back
```

### Step 2: Rebuild and restart

```bash
sudo nixos-rebuild switch --flake .#cypher-nixos
sudo systemctl restart redis-
redis-cli ping
```

Given the ephemeral (`save = []`) configuration, there's no persisted data to migrate — *this is close to a non-event.* Revisit this procedure if Valkey is ever switched to persistent mode.

---

## Troubleshooting

### `nix flake check` fails on an extension not yet built for the new Postgres major version

Don't proceed with the version bump until this is resolved — *either wait for the extension's `nixpkgs` package to catch up, or reconsider the timing of the bump.*

### Restore into the new version fails partway through

Roll back to the pre-upgrade Btrfs snapshot *(see [RBK_004](RBK_004_dbms_data_backup_and_restore.md) Procedure A, Step 3)* rather than trying to debug a partial restore — cheaper and more certain than patching a half-migrated database.

---

## Rollback

1. Stop the service on the new version.
2. Revert the `package`/`dataDir` change in `dbmss.nix`.
3. `nixos-rebuild switch`.
4. Restore the pre-upgrade Btrfs snapshot onto the original `dataDir` path (same mechanics as [RBK_004](RBK_004_dbms_data_backup_and_restore.md) Procedure A, Step 3).

---

## Related

- Runbook: [RBK_004 — DBMS Data Backup & Restore](RBK_004_dbms_data_backup_and_restore.md)
- Runbook: [RBK_007 — Adding a New DBMS Subvolume](RBK_007_adding_a_new_dbms_subvolume.md)
- ADR: [ADR_017 — DBMS Subvolume Architecture](../decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md)

---

<!--
METADATA
Created: 2026-08-18
Updated: 2026-08-18
Tested by: Cypher Whisperer
-->