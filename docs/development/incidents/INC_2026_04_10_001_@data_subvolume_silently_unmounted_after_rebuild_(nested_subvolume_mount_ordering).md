# INC-2026-04-15-001: `@data` Subvolume Silently Unmounted After Rebuild (Nested-Subvolume Mount Ordering)

<!-- NOTE: Date is a best guess. This entry was done late (2026-08-19); was originaly not documented, then informally in scripts/mount.sh. After actual date confirmation rename the file to match. -->

**ID:** INC_2026_04_10_001 <!-- CONFIRM: may already exist as a stub — check before creating a duplicate --> 
**Date:** 2026-04-10 <!-- TODO: confirm actual date -->
**Severity:** Medium <!-- suggested: looked like total data loss (high anxiety, real risk of destructive response), but no data was actually lost and root cause is now fully understood and designed around -->
**Status:** Resolved
**Reported by:** CypherWhisperer

---

## Summary

After a NixOS rebuild on CypherOS's first installation, `~/DATA` *(the intended mountpoint for a dedicated `@data` Btrfs subvolume, nested inside `@home`)* appeared completely empty.

Initial assessment was total data loss. Diagnosis via a live ISO environment *(BlendOS)* found the data was still physically present on disk — *the subvolume had lost its mount, not its contents.*

At the time, the root mechanism was not understood, so `@data` was treated as an inherently high-risk pattern and replaced with a plain directory inside `@home`.

The actual root cause was only identified later (with the help of Claude AI) *(2026-08-18, during DBMS subvolume architecture work):* a known, still-open NixOS/systemd issue with mount ordering for subvolumes nested inside other subvolumes.

---

## Timeline

| Time                                        | Event                                                                                                                                                                                                                                                                |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-04-15 (approx.) <!-- TODO: confirm --> | `@data` subvolume created, nested inside `@home`, mounted at `~/DATA` during initial CypherOS install                                                                                                                                                                |
| _TODO_                                      | A subsequent `nixos-rebuild switch` occurs                                                                                                                                                                                                                           |
| _TODO_                                      | `~/DATA` found empty after the rebuild; initially assessed as total data loss                                                                                                                                                                                        |
| _TODO_                                      | Booted a live ISO environment *(BlendOS)* to diagnose                                                                                                                                                                                                                |
| _TODO_                                      | Confirmed via the live environment that the underlying data was still present on disk — *not deleted*                                                                                                                                                                |
| _TODO_                                      | Concluded the subvolume had "lost the link" to its data during the build process; exact mechanism not understood at the time                                                                                                                                         |
| _TODO_                                      | Resolution applied: `@data` subvolume dropped; `~/DATA` recreated as a plain directory inside `@home` *(see `scripts/mount.sh` comments, pre-2026-08-18 version.)*                                                                                                   |
| 2026-08-18                                  | Root cause identified during DBMS subvolume architecture design: confirmed against [nixpkgs#217179](https://github.com/NixOS/nixpkgs/issues/217179) — systemd does not reliably honor mount-unit ordering for a subvolume nested inside an already-mounted subvolume |

---

## Impact

- **Components affected:** `~/DATA` (personal data directory), initial trust in Btrfs subvolume nesting as a safe pattern.
  
- **Data affected:** None, ultimately — data was intact on disk throughout; only its _mount_ was affected. At the time, this was not known and the incident was treated as if data loss had occurred.
  
- **Time lost:** _TODO — approximate hours spent diagnosing via live ISO boot_
- **Work affected:** Delayed/altered the original data-subvolume architecture plan; `~/DATA` ran as a plain directory *(not independently snapshottable)* from this incident until the planned 2026-08-18-onward follow-up session to recreate `@data` properly

---

## Root Cause

A subvolume (`@data`) was declared as a **separately mounted** filesystem, nested at a path (`~/DATA`) _inside_ another already-mounted subvolume (`@home`).

Systemd's mount-unit ordering does not reliably guarantee that a nested mount comes up correctly relative to its parent's own mount unit — this is a confirmed, still-open upstream issue *([nixpkgs#217179](https://github.com/NixOS/nixpkgs/issues/217179), "systemd doesn't respect `fileSystems.<name>.depends`").*

When the `@data` mount unit failed or raced during a rebuild, `~/DATA` silently fell back to resolving as the plain (empty) directory that's actually part of `@home`'s own subvolume — *no error was surfaced, and the data on the actual `@data` subvolume simply became unreachable through that path, not deleted.*

The nesting itself — *not Btrfs subvolumes in general, and not "non-deterministic" behavior as originally suspected — is the specific, narrow cause.*

---

## Resolution

**At the time (2026-04-10-ish):** `@data` subvolume dropped entirely; `~/DATA` recreated as a plain directory inside `@home`. This eliminated the separately-mounted-nested pattern and therefore the failure mode, at the cost of losing independent snapshot/backup treatment for personal data.

**Structural resolution (2026-08-18):** Root cause fully identified and designed around for all _new_ subvolume work — every DBMS subvolume added this session *(`@dbms_postgres`, `@dbms_mariadb`, `@dbms_valkey`, `@dbms_meilisearch`, `@dbms_mongo`, `@dbms_neo4j`)* is a **top-level sibling** of `@nixos-root`/`@home`/`@nix-store`/`@swap`, mounted directly off the Btrfs top-level *(`subvolid=5`),* never nested inside another mounted subvolume — *structurally immune to this failure class.*

### Changes Made

| Type    | Reference                                                                            | Description                                                                                                                |
| ------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| Commit  | *TODO*                                                                               | Original fix: dropped `@data`, flattened `~/DATA` to a plain directory                                                     |
| ADR     | [ADR_017](../../project/decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md) | DBMS subvolume architecture — codifies the top-level-sibling, never-nested principle directly in response to this incident |
| Journal | [2026_08_18](../journal/2026_08_18_dbms_stack_setup.md)                              | Documents the root-cause identification and its role in the DBMS subvolume design                                          |
| Script  | `scripts/mount.sh`                                                                   | Carries an inline comment recording this incident informally — this report formalizes it                                   |

<!-- No changelog/runbook row — this incident didn't produce a standalone runbook; the prevention IS the subvolume architecture, covered by ADR_017 -->

---

## Contributing Factors

- No documented convention at the time for how nested vs. sibling subvolume mounts behave differently under systemd — the nesting risk wasn't known to be a risk until this incident.
  
- No pre-existing incident-log entry capturing this at the time it happened, which meant the _specific, narrow_ lesson *("nesting is the problem")* got generalized into a broader, less precise one *("subvolumes within subvolumes are unsafe")* that persisted until the 2026-08-18 session re-examined it against the actual upstream issue.
  
- No automated verification *(e.g. a boot-time check that expected mountpoints are actually populated)* existed to catch the empty-directory fallback before it looked like data loss.

---

## Prevention

- **Structural:** All new subvolumes follow the top-level-sibling convention (`@dbms_*` set — see [ADR_017](../../project/decisions/ADR_017_2026_08_18_dbms_subvolume_architecture.md)); this is now the standing default, not something to re-decide per subvolume.
  
- **Process:** When `~/DATA` is migrated to a proper `@data` subvolume in the planned follow-up session, it will be provisioned as a top-level sibling from the start — *this incident is the direct reason that migration is being treated carefully rather than as a quick redo of the original attempt.*
  
- **Documentation:** This report itself — the informal comment in `scripts/mount.sh` is useful but isn't discoverable the way a linked incident report is; this closes that gap.

---

## Lessons Learned

The immediate lesson *("don't nest a separately-mounted subvolume inside another mounted subvolume")* is narrower and more actionable than the lesson originally drawn *("subvolume nesting is inherently risky/non-deterministic")* — the broader version was safe but overcautious, and cost the system independent snapshot/backup treatment for `~/DATA` for longer than the actual risk justified.

Worth remembering generally: when a system behaves unexpectedly and the root cause isn't found, the natural response is to generalize the avoidance as broadly as possible — reasonable in the moment, but worth revisiting once the actual mechanism is understood, rather than letting the overcautious version become permanent by default.

---

<!--
METADATA Opened: 2026-04-10 (approx., TODO confirm)
Resolved: 2026-08-18 (structural resolution; the immediate 2026-04-10 fix resolved the symptom)
Related journal entry: 2026_08_18_dbms_stack_setup
-->