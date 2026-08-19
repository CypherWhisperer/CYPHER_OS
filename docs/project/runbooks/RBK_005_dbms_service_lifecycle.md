# Runbook: DBMS Service Lifecycle *(Start/Stop/Status)*

**Last verified:** 2026-08-18
**Host:** `cypher-nixos`
**Module:** `modules/devops/dbmss.nix`
**Trigger:** Reactive *(start of a dev session, end of a dev session.)*
**Estimated time:** <1 minute

---

## When To Use This Runbook

Any time you're starting or ending a development session that needs Postgres, MariaDB, and/or Valkey — these run on-demand, not always-on (see [ADR_019](../decisions/ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)).

---

## Prerequisites

- Active session on `cypher-nixos` with `sudo` access.

---

## Procedure

### Step 1 — Start what you need

```bash
sudo systemctl start postgresql   # primary relational
sudo systemctl start mysql        # secondary/compat (MariaDB)
sudo systemctl start redis-       # cache (Valkey) — note the trailing hyphen, it's the default instance name
```

**Expected output:** no output on success (systemd default).

**If this fails:**
- `journalctl -u <unit> -n 50` — first-ever start against a fresh `dataDir` runs `initdb`/equivalent and can take longer than a normal start.
- A genuine failure usually points at a mount *(`/dbms/<name>` not mounted)* or permission issue.

### Step 2 — Verify

```bash
systemctl status postgresql mysql redis- --no-pager
```

**Expected result:** `Active: active (running)` for each you started.

### Step 3 — Confirm connectivity

```bash
sudo -u postgres psql -c '\l'                 # Postgres
sudo mysql -e 'SHOW DATABASES;'               # MariaDB
redis-cli ping                                # Valkey (wire-compatible, redis-cli works)
```

**Expected result:** a database/table listing, or `PONG` for Valkey.

### Step 4 — Stop when done

```bash
sudo systemctl stop postgresql mysql redis-
```

---

## Troubleshooting

### Service won't start, `journalctl` shows a mount-related error

Confirm the relevant subvolume is actually mounted:
- `mount | grep /dbms/`.
- If missing, `sudo systemctl start dbms-postgres.mount` *(or the equivalent unit for the DB in question)* then retry.

### First start after enabling a previously-dormant DB takes a while / looks stuck

**Expected:**
- `initdb`/cluster initialization only happens once, on the very first start against an empty `dataDir`.
- Give it a minute before assuming it's hung; check `journalctl -u <unit> -f` for live progress.

### Forgot which services are currently running

```bash
systemctl list-units --type=service --state=running | grep -E 'postgresql|mysql|redis-'
```

---

## Rollback

Not applicable — starting/stopping a service has no state to roll back. If a _start_ leaves the data in a bad state, see [RBK_004](RBK_004_dbms_data_backup_and_restore.md).

---

## Related

- ADR: [ADR_019](../decisions/ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)
- Runbook: [RBK_004 — DBMS Data Backup & Restore](RBK_004_dbms_data_backup_and_restore.md)

---

<!-- METADATA
Created: 2026-08-18
Updated: 2026-08-18
Tested by: Cypher Whisperer
-->