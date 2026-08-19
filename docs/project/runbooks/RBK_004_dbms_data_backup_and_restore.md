# Runbook: DBMS Data Backup & Restore

**Last verified:** 2026-08-18
**Host:** `cypher-nixos`
**Module:** `modules/devops/dbmss.nix`
**Trigger:** Scheduled *(native dumps)* | Reactive *(snapshots, restores)*
**Estimated time:** ~5 minutes per procedure

_Note: this runbook covers three related procedures rather than one linear sequence — DBMS backup/restore on CypherOS spans a scheduled automated layer and two manual/reactive layers. See [ADR_020](../decisions/ADR_020_2026_08_18_dbms_backup_strategy.md) for why._

---

## When To Use This Runbook

1. **Procedure A:** Before a risky change *(schema migration, extension upgrade)* — take a snapshot.
2. **Procedure B:** To verify or manually trigger the automated dump.
3. **Procedure C:** To actually recover from data loss.

---

## Prerequisites

- Active session on `cypher-nixos` with `sudo` access.
- `modules/devops/dbmss.nix` active *(`cypher-os.devops.enable` and `cypher-os.devops.databases.enable` both `true`).*
- For Procedure A: target subvolume mounted at `/dbms/<name>`.

---

## Procedure A: Manual Btrfs Snapshot *(fast local rollback point)*

### Step 1 — Take a read-only snapshot before a risky change

```bash

sudo btrfs subvolume snapshot -r /dbms/postgres /dbms/.snapshots/postgres_$(date +%Y%m%d-%H%M%S)
```

**Expected output:**
- `Create a snapshot of '/dbms/postgres' in '/dbms/.snapshots/postgres_...'` 

**If this fails:**
    - confirm `/dbms/.snapshots/` exists *(`mkdir -p /dbms/.snapshots` first if not)* and you're running as root.

### Step 2 — List existing snapshots

```bash
sudo btrfs subvolume list /dbms
```

### Step 3 — Roll back if needed

```bash
sudo systemctl stop postgresql   # stop the DB before touching its data dir
sudo btrfs subvolume delete /dbms/postgres
sudo btrfs subvolume snapshot /dbms/.snapshots/postgres_<timestamp> /dbms/postgres
sudo systemctl start postgresql
```

**Expected result:**
- service starts cleanly against the restored snapshot's data.

**If this fails:**
    - confirm the snapshot wasn't itself taken read-only in a way that blocks the promoted copy from being writable — *the second `snapshot` call (without `-r`) creates a writable copy, which is required here.*

---

## Procedure B: DBMS-Native Backup *(automated + manual trigger)*

### Step 1 — Confirm the timer is active

```bash
systemctl list-timers pg-backup.timer mariadb-backup.timer
```

**Expected output:** both listed with a `NEXT` time within the next 24h.

### Step 2 — Trigger a dump manually *(doesn't wait for the schedule)*

```bash
sudo systemctl start pg-backup.service
sudo systemctl start mariadb-backup.service
```

**Expected output:**
- Exits cleanly *(`systemctl status pg-backup.service` shows `Main PID exited, code=exited, status=0`).*

**If this fails:**
    - Check `journalctl -u pg-backup.service -n 50` — most likely cause is the underlying DB service failing to start *(the backup unit's `wants`/`after` should start it automatically, but a bad `dataDir` state would surface here).*

### Step 3 — Verify the dump landed

```bash
ls -lh /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS/postgres/
ls -lh /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS/mariadb/
```

**Expected result:** a `dump-<timestamp>.sql.gz` file, non-zero size, dated within the last few minutes.

---

## Procedure C: Restore From a Native Dump

### Step 1 — Stop the service if running

```bash
sudo systemctl stop postgresql
```

### Step 2 — Restore (Postgres example)

```bash
sudo systemctl start postgresql   # need it running to restore INTO
gunzip -c /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS/postgres/dump-<timestamp>.sql.gz \
  | sudo -u postgres psql
```

**Expected output:**
- a stream of `CREATE`/`ALTER`/`COPY` statement acknowledgements, no `ERROR` lines.
  
**If this fails:**
- a partial restore against a non-empty database is the most common cause — restoring `pg_dumpall` output cleanly usually wants a fresh cluster *(fresh `dataDir` and a re-run of `initdb`)* rather than restoring on top of existing data.

### Step 3 — MariaDB equivalent

```bash
sudo systemctl start mysql
gunzip -c /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS/mariadb/dump-<timestamp>.sql.gz \
  | sudo mysql
```

---

## Troubleshooting

### Backup timer fires but the dump file is empty or missing

Check that the corresponding DB service actually came up *(`systemctl status postgresql`/`mysql`)* — the `wants`/`after` relationship should start it, but a mount or `dataDir` permission issue would prevent that silently from the timer's perspective.

### `find -mtime +14 -delete` removed a dump you needed

Retention is 14 days by design *(see `retentionDays` in `modules/devops/dbmss.nix`).*

There is currently no longer-term archive beyond what's already been mirrored to the external HDD — *if the HDD mirror also missed the window, the dump is gone.*

That could be revised for a better targetted strategy.

---

## Rollback

Not applicable in the traditional sense — this runbook _is_ the rollback mechanism for DBMS data. If a restore itself goes wrong, the next-oldest snapshot *(Procedure A)* or dump *(Procedure B/C)* is the fallback.

---

## Related

- ADR: [ADR_020](../decisions/ADR_020_2026_08_18_dbms_backup_strategy.md)
- Guide: `docs/project/guide_btrfs_snapshots.md`
- Guide: `docs/project/guide_backup_tooling.md`
- Runbook: [RBK_005 — DBMS Service Lifecycle](RBK_005_dbms_service_lifecycle.md)

---

<!-- METADATA
Created: 2026-08-18
Updated: 2026-08-18
Tested by: Cypher Whisperer
-->