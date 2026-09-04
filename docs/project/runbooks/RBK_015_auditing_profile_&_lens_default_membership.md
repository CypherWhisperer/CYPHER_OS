# Runbook: Auditing Profile & Lens Default Membership

**Last verified:** 2026-09-04
**Host:** `cypher-nixos` (audit applies to the whole `src/` tree, host-agnostic)
**Module:** [`docs/project/profile_membership.md`](../profile_membership.md)
**Trigger:** Reactive (run whenever drift is suspected) — recommended as a periodic scheduled check too, e.g. before closing out any Phase-5-style category batch
**Estimated time:** ~15 minutes

---

## When To Use This Runbook

You suspect `docs/project/profile_membership.md` no longer matches the actual `cypherOsProfile`/`cypherOsLens`-conditional defaults in the codebase — e.g. it's been a while since the last audit, several categories were touched in one session, or [RBK_009](RBK_009_adding_a_new_cypher_os_category.md)/[RBK_010](RBK_010_adding_a_leaf_to_an_existing_category.md)'s table-update step was skipped somewhere along the way.

---

## Prerequisites

- Clean or at least reviewable working tree — you'll be reading `git diff`-able changes to `profile_membership.md`.
- Repo checked out with `src/` fully present *(not a partial sparse-checkout).*

---

## Procedure

### Step 1 — Grep for every profile/lens-conditional expression

```bash
grep -rn 'cypherOsProfile ==\|cypherOsLens\|builtins.elem cypherOsProfile' src/
```

**Expected output:**
- a `file:line` match for every live profile- or lens-conditional default in the tree.

**If this fails:**
- zero matches means either no conditional defaults exist yet, or the search pattern is stale — *check whether the `module-arg` names changed since this runbook was last verified.*

---

### Step 2 — Check every match has a table row

**For each match from Step 1:**
- confirm the option path, condition, and source file appear as a row in the correct section of `docs/project/profile_membership.md`.
- Note any match with no corresponding row.

---

### Step 3 — Check every table row still has a match

**For each row in `profile_membership.md`:**
- Confirm it still corresponds to a live match from Step 1 — same option path, same condition, same file.
- Note any row whose source file/line no longer contains that condition *(moved, refactored, or removed since the row was written).*

---

### Step 4 — Reconcile

Add rows for anything found missing in Step 2. Correct or remove rows found stale in Step 3.

---

### Step 5 — Verify

```bash
grep -rc 'cypherOsProfile ==\|cypherOsLens\|builtins.elem cypherOsProfile' src/ | awk -F: '{s+=$2} END {print s}'
```

**Expected result:**
- this count matches the total number of populated rows across all sections of `profile_membership.md`.
- Update the `**Last audited:**` field at the top of the file to today's date once they match.

---

## Troubleshooting

### A grep match is inside a commented-out line

Nix's `#` comments still match plain-text grep. Visually confirm the line is live code before treating it as something the table needs to reflect.

### A condition is behind a `let`-bound alias, not written inline

e.g. `let wantsDesktop = cypherOsProfile == "desktop"; in ... cfg.enable = lib.mkDefault wantsDesktop;` — `grep` still finds the alias's *definition* line, but make sure the table's source-file entry points there *(where the condition is defined),* not to every place the alias gets reused, which would otherwise inflate the row count against Step 5's check.

---

## Rollback

This is a documentation-only audit — *no system state changes.* If a reconciliation edit turns out wrong, revert `docs/project/profile_membership.md` via *git.*

---

## Related

- Convention: [profile_defaults.md](../../contributing/conventions/profile_defaults.md)
- Runbook: [RBK_009](RBK_009_adding_a_new_cypher_os_category.md), [RBK_010](RBK_010_adding_a_leaf_to_an_existing_category.md)

---

<!--
METADATA
Created:    2026-09-04
Updated:    2026-09-04
Tested by:  Cypher Whisperer
-->