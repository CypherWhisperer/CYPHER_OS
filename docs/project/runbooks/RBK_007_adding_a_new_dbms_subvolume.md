# Runbook: Adding a New DBMS Subvolume

**Last verified:** 2026-08-18
**Host:** `cypher-nixos`
**Module:** `modules/devops/dbmss.nix`, `scripts/create_dbms_subvolumes.sh`
**Trigger:** Reactive — a DBMS outside the current six-category set is needed
**Estimated time:** ~20 minutes

---

## When To Use This Runbook

When a genuinely new DBMS *(not already one of `postgres`/`mariadb`/`valkey`/`meilisearch`/`mongo`/`neo4j`)* needs a home — e.g. ClickHouse if an analytics workload eventually justifies it *(see `modules/devops/dbmss.nix` comments on why it's currently excluded).*

---

## Prerequisites

- Confirm the target device *(`findmnt -no SOURCE /` — do not assume it's still `/dev/sda1` without checking.)*
- Decide the subvolume name following the established convention: `@dbms_<name>`.
- `sudo` access on `cypher-nixos`.

---

## Procedure

### Step 1 — Add the name to the retrofit script's list

Edit `scripts/create_dbms_subvolumes.sh`, add the new name to `DBMS_NAMES`:

```bash
DBMS_NAMES=(postgres mariadb valkey meilisearch mongo neo4j clickhouse)
```

### Step 2 — Run the retrofit script

```bash
sudo bash ./scripts/create_dbms_subvolumes.sh
```

**Expected output:** matches the pattern from the 2026-08-18 run — a `btrfs subvolume list` sanity dump, then `Create subvolume '.../@dbms_clickhouse'`, then unmount/done.

**If this fails:** re-check the target partition argument matches the actual device.

### Step 3 — Add to `dbmsSubvolumes` in `modules/devops/dbmss.nix`

```nix
let
  dbmsSubvolumes = [
    "postgres" "mariadb" "valkey" "meilisearch" "mongo" "neo4j"
    "clickhouse"
  ];
```

This automatically extends the `fileSystems` block *(via `lib.genAttrs`)* to mount the new subvolume — no separate `fileSystems` entry needs to be hand-written.

### Step 4 — Add the ownership rule

```nix
systemd.tmpfiles.rules = [
  # ... existing rules ...
  "d /dbms/clickhouse 0700 clickhouse clickhouse - -"
];
```

Confirm the system username matches what the actual service module creates — don't assume it matches the subvolume name.

### Step 5 — Rebuild and verify the mount

```bash
sudo nixos-rebuild switch --flake .#cypher-nixos
mount | grep /dbms/clickhouse
ls -la /dbms/clickhouse
```

Expected result: mounted, owned by the correct system user, `0700`.

### Step 6 — Add the actual service block

Follow [RBK_006](RBK_006_enabling_a_dormant_dbms.md) from Step 1 onward for wiring up the service itself.

---

## Troubleshooting

### `create_dbms_subvolumes.sh` reports the subvolume already exists

Safe — the script's existing `if [[ -d "$target" ]]` check skips creation. Confirms the script is idempotent; nothing to fix.

### New `fileSystems` entry doesn't appear after rebuild

Confirm the name was actually added to `dbmsSubvolumes` in `dbmss.nix` *(not just the bash script's `DBMS_NAMES`)* — the two lists are independent and both need updating.

---

## Rollback

If the subvolume was created but you want to undo the Nix-side wiring:
- Revert the `dbmsSubvolumes` and `tmpfiles.rules` additions and rebuild.
- The subvolume itself is not deleted automatically — remove it manually with `btrfs subvolume delete` *(mounted at the top-level, as in the retrofit script)* only if you're certain nothing of value is in it.

---

## Related

- ADR: [ADR_017](../decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md)
- Runbook: [RBK_006 — Enabling a Dormant DBMS](RBK_006_enabling_a_dormant_dbms.md)
- Script: `scripts/create_dbms_subvolumes.sh`

---

<!--
METADATA
Created:    2026-08-18
Updated:    2026-08-18
Tested by:  Cypher Whisperer
-->