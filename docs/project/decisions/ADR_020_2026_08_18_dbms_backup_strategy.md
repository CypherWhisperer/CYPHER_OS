# ADR_020_2026_08_18: DBMS Backup Strategy

**Date:** 2026-08-18
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

No DBMS data currently has any backup coverage beyond whatever the general filesystem happens to preserve.

The existing personal backup workflow is a manual, occasional `rsync` mirror of `~/DATA` to an external HDD *(no NAS, no always-reachable destination, no prior experience with dedicated backup tooling like restic/borg or with Btrfs snapshots).*

---

## Decision

A two-layer strategy:

1. **DBMS-native dumps, automated:**
    - Daily `systemd.timer`-triggered `pg_dumpall`/`mariadb-dump`, gzip-compressed, timestamped, written to `${backupRoot}/{postgres,mariadb}` *(currently `/home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS/`, planned to migrate to a `${data_dir}`-relative path once [ADR pending — global paths via `cypher-os` Nix options] lands).*
      
    - 14-day retention via `find -mtime +14 -delete`.
    - Because the target directory already lives inside the tree manually mirrored to the external HDD, no new backup destination or offsite mechanism was introduced — the existing `rsync` habit picks these up automatically on the next manual backup session.
      
2. **Btrfs snapshots, manual/explicit for now:**
    - A separate, faster, local-only safety net *(`btrfs subvolume snapshot -r`)* for fast rollback during active dev *(e.g. undoing a bad migration)* — not a substitute for the dumps above, and not currently part of the offsite path *(would require the external HDD itself to be Btrfs-formatted, which it is not).*


Since Postgres/MariaDB run on-demand ([ADR_019](ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)), the backup timers explicitly `wants`/`after` the relevant service unit to wake it for the dump — *the one deliberate exception to the on-demand posture.*

`restic/borg` and a NAS-based destination were evaluated and deliberately deferred, not rejected outright.

---

## Reasoning

Layering native-tool dumps *(always logically consistent, portable, filesystem-agnostic)* with Btrfs snapshots *(near-instant, ~zero space cost, but Btrfs-to-Btrfs only and not logically-consistent in the same way)* covers two different failure modes without redundancy:
- "I need to undo my last schema change right now" *(snapshot)* vs. "I need an actual portable disaster-recovery artifact" *(native dump).*

Automating only the piece with an always-reachable target *(the internal disk, via `systemd.timer`)* — and deliberately _not_ trying to automate the external-HDD step, which has no reliably-present target — respects the actual current workflow rather than introducing infrastructure *(a NAS, always-on remote destination)* that doesn't exist yet.

`restic/borg`'s real value-add over the existing `rsync --delete` mirror is version history *(recovering a file as it existed several backups ago, not just the latest mirrored state)* — a real gap, but not one that has caused a problem yet, and adopting either tool later is a small, low-risk, purely additive change *(`restic init` + `restic backup` in place of the current `rsync` command)* whenever that gap actually bites.

---

## Alternatives Considered

### Adopt restic/borg immediately

**Deferred (not rejected):**
- See Reasoning.
- To be revisit once either 
    1. A reachable-often-enough destination exists *(NAS or similar)* or
    2. A concrete *"I wish I had an older version of this file"* moment actually occurs.

### Rely on Btrfs snapshots alone, skip DBMS-native dumps

**Rejected:**
- Snapshots are Btrfs-to-Btrfs only, not portable off this machine or across a filesystem reformat, and aren't a substitute for a real disaster-recovery artifact.

### Automate the external-HDD `rsync` step itself via a timer

**Rejected:**
- The drive isn't reliably present *(manually plugged in),* so there's nothing for a scheduled job to target reliably.

### Have the DB services themselves stay running so backup timers don't need to wake them

**Rejected:**
- Would contradict [ADR_019](ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)'s compute-preservation rationale for one narrow convenience.
- `wants`/`after` on the backup unit solves the same problem without compromising the on-demand posture.

---

## Consequences

**Positive:**

- DBMS data now has real, automated, unattended local backup coverage where previously there was none.
- Zero new infrastructure or destinations introduced — *backups ride the existing manual `rsync` habit.*
- Two complementary recovery paths *(fast local rollback vs. portable disaster recovery)* cover meaningfully different failure modes.

**Negative / Trade-offs:**

- Coverage is currently limited to Postgres and MariaDB — Valkey *(ephemeral, nothing to protect by design),* and the dormant Meilisearch/MongoDB/Neo4j *(no data yet)* are explicitly out of scope until they're actually enabled.
  
- The offsite step *(external HDD)* remains entirely manual — a missed/forgotten plug-in session means the true offsite backup lags behind the local dumps by however long it's been.
  
- Btrfs snapshots are explicit-only for now *(no `snapper`/`btrbk` automation)* — deliberate, to build manual familiarity with the workflow before automating a retention policy not yet understood from experience.

**Neutral / Operational:**

- `backupRoot` is currently hardcoded per-DB; migrating to a `cypher-os`-namespaced global path option is tracked as a follow-up (see journal, 2026-08-18).
- See [RBK_004](../runbooks/RBK_004_dbms_data_backup_and_restore.md) for the day-to-day backup/restore procedure across both layers.