# Runbook: [Procedure Name]

<!--
A runbook is a step-by-step operational procedure. It answers:
"How do I do X?" for X that happens regularly enough to standardize,
or that is critical enough that you cannot afford to improvise.

Runbooks are for DOING, not for UNDERSTANDING.
Keep them terse. Every step is an action verb.
-->

**Last verified:** YYYY-MM-DD
**Host:** `[e.g. cypher-nixos]`
**Module:** `[e.g. modules/devops/observability.nix]`
**Trigger:** `[Scheduled | Reactive]`
**Estimated time:** ~N minutes

---

## When To Use This Runbook

<!-- REQUIRED: One or two sentences. What situation triggers this procedure? -->

_TODO: One or two sentences. What situation triggers this procedure?_

---

## Prerequisites

<!-- REQUIRED: Everything that must be true before starting. -->

- _TODO (e.g. "Active NixOS session on cypher-nixos")_
- _TODO (e.g. "`cypher-os.devops.secrets.enable = true` in host configuration")_
- _TODO (e.g. "age key present at `~/.config/sops/age/keys.txt`")_

---

## Procedure

<!--
Every step is an action verb.
If a step can fail, note what failure looks like and what to do.
-->

### Step 1 — [Action]

```bash
# command here
```

Expected output: _TODO_
If this fails: _TODO_

---

### Step 2 — [Action]

_TODO_

---

### Step N — Verify

```bash
# verification command
```

Expected result: _TODO_

---

## Troubleshooting

<!-- OPTIONAL but strongly recommended: What can go wrong, and how to recover? -->

### [Problem scenario 1]

_TODO: Symptom and resolution._

### [Problem scenario 2]

_TODO_

---

## Rollback

<!-- REQUIRED: How to undo this procedure if something goes wrong. -->

_TODO or "This procedure is not reversible. Refer to the relevant incident log for recovery guidance."_

---

## Related

<!-- Related documents:
- [ADR-NNN](../decisions/ADR_NNN_title.md)
- [INC-YYYY-MM-DD-NNN](../../development/incidents/INC_YYYY_MM_DD_NNN.md)
-->

- Runbook: _TODO or remove_
- Incident: _TODO or remove_
- ADR: _TODO or remove_
- Module doc: `docs/modules/[subsystem]/[module].md`

---

<!--
METADATA
Created:    YYYY-MM-DD
Updated:    YYYY-MM-DD
Tested by:  Cypher Whisperer
-->
