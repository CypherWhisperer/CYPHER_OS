# Runbook: Enabling a Dormant DBMS *(Valkey extra instance, MongoDB, Neo4j, Meilisearch)*

**Last verified:** 2026-08-18
**Host:** `cypher-nixos`
**Module:** `modules/devops/dbmss.nix`
**Trigger:** Reactive — *a real project now needs one of these.*
**Estimated time:** ~15–30 minutes *(config + first-start verification.)*

---

## When To Use This Runbook

When a project actually needs MongoDB, Neo4j, Meilisearch, or a _persistent_ (non-ephemeral) Valkey instance running — their subvolumes already exist ([ADR_018](../decisions/ADR_018_2026_08_18_provisioning_dormant_dbms_subvolumes_ahead_of_need.md)), so this is pure Nix-config work, no disk operations.

---

## Prerequisites

- Confirm which DBMS you're enabling and its correct real option names — **do not assume `dataDir` works the same way across modules.** MongoDB uses `dbpath`, Neo4j uses `directories.home`, and Meilisearch's storage-path option was **not confirmed** as of this writing — verify via `nixos-option services.meilisearch` or `search.nixos.org` before assuming it isn't hardcoded like Redis.
  
- The corresponding `/dbms/<name>` mountpoint already exists and is owned correctly *(verify: `ls -la /dbms/<name>` should show the right system user as owner, `0700`).*

---

## Procedure

### Step 1 — Add the service block in `modules/devops/dbmss.nix`

MongoDB example:

```nix
services.mongodb = {
  enable = true;
  package = pkgs.mongodb-ce;   # matches ADR_016's package decision
  dbpath = "/dbms/mongo";
  bind_ip = "127.0.0.1";
};
```

Neo4j example:

```nix
services.neo4j = {
  enable = true;
  directories.home = "/dbms/neo4j";
};
```

Meilisearch — **confirm the storage-path option first** (see Prerequisites). If it turns out hardcoded, use the bind-mount pattern instead (see Step 1a).

### Step 1a — If the module hardcodes its storage path *(Redis/Valkey pattern)*

```nix
fileSystems."/var/lib/<hardcoded-path>" = {
  device = "/dbms/<name>";
  options = [ "bind" ];
};
systemd.services."<unit-name>".serviceConfig.RequiresMountsFor = [ "/var/lib/<hardcoded-path>" ];
```

### Step 2 — Add `RequiresMountsFor`, matching the existing Postgres/MariaDB pattern

```nix
systemd.services.mongodb.serviceConfig.RequiresMountsFor = [ "/dbms/mongo" ];
```

### Step 3 — Decide on-demand vs always-on

If this DB should follow the same on-demand posture as Postgres/MariaDB/Valkey ([ADR_019](../decisions/ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)):

```nix
systemd.services.mongodb.wantedBy = lib.mkForce [ ];
```

### Step 4 — Rebuild

```bash
sudo nixos-rebuild switch --flake .#cypher-nixos
```

**Expected output:** activation completes without error.

**If this fails:** most likely an evaluation error from a wrong option name — re-check against the actual module source, not assumption/memory.

### Step 5 — Verify

```bash
sudo systemctl start mongodb   # or whichever unit
systemctl status mongodb --no-pager
```

**Expected result:** `Active: active (running)`, and data actually lands under `/dbms/mongo` *(confirm with `ls -la /dbms/mongo` after some activity).*

---

## Troubleshooting

### Service starts but writes data somewhere unexpected

Usually means the option name assumption was wrong *(exactly the `dataDir` vs `dbpath` trap this runbook exists to prevent)* — re-verify against the actual module source or `nixos-option`.

### Permission denied on first start

Confirm the `tmpfiles.rules` entry for this DB's subvolume uses the _correct_ system user/group — module-created users can have non-obvious default names; verify with `id <expected-user>` before assuming it matches what's in `dbmss.nix`.

---

## Rollback

Set `enable = false` *(or remove the block entirely)* and `nixos-rebuild switch` again. The subvolume and any data written to it are untouched — this only affects whether the service runs, not the underlying storage.

---

## Related

- ADR: [ADR_018](../decisions/ADR_018_2026_08_18_provisioning_dormant_dbms_subvolumes_ahead_of_need.md)
- ADR: [ADR_017](../decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md)
- Runbook: [RBK_007](RBK_007_adding_a_new_dbms_subvolume.md)

---

<!-- METADATA
Created: 2026-08-18
Updated: 2026-08-18
Tested by: Cypher Whisperer
-->