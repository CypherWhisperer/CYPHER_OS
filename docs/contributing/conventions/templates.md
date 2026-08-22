# Working With Templates

This document is the guide, not just the index. `docs/_templates/` holds the raw files; this page explains what each document type _is_, when to reach for it, how it moves through its lifecycle, and how the three *(ADR, RFC, Runbook)* relate to each other. Read this before opening a template for the first time.

Related:
. [`naming.md`](naming.md) (file/attribute naming used throughout these templates)
. [ADR template](../../_templates/adr_template.md)
. [RFC template](../../_templates/rfc_template.md)
. [Runbook template](../../_templates/runbook_template.md)

---

## The three document types, in one sentence each

- **ADR** — records a decision that has been made, and why.
- **RFC** — proposes a decision that has _not_ been made yet, so it can be thought through and argued with before anything is built.
- **Runbook** — tells you the steps to _do_ something that recurs, or that is too risky to improvise.

If you're not sure which one you're writing:
- An ADR is written in the past tense about a choice .
- An RFC is written in the future tense about a choice not yet locked.
- A runbook has no tense at all — *it's just verbs.*

---

## ADRs

### When to write one

Any decision that changes the shape of the system going forward and that a future session would benefit from not having to re-litigate. Namespace shape, module architecture, a package/tool selection with real trade-offs, a security posture choice. Not every change needs one — ***a leaf module adding a new package with an obvious default doesn't.***

### Status lifecycle

`Proposed → Accepted → (stays Accepted, indefinitely, unless...) → Deprecated | Superseded by ADR-NNN`

An ADR practically never goes back to `Proposed` once `Accepted`. If the decision needs revisiting, you either **amend** it or **supersede** it — *see below for which.*

### Amendment vs. Supersession

**Amend** when the original decision's core reasoning still holds, and you're recording an incremental correction, clarification, or extension to it — something that doesn't invalidate why the decision was made, only adjusts a detail of how it's carried out. Amending means:

- The ADR's **status stays `Accepted`** — it is not superseded, not deprecated.
- The original **Decision / Reasoning / Alternatives / Consequences** sections are left untouched — history isn't rewritten.
- A dated **`## Amendment — YYYY-MM-DD`** section is appended to the bottom of the same file, stating what changed and why, in the same terse style as the rest of the document. No new ADR number is consumed.
- Multiple amendments simply stack, each with its own dated heading, in the order they happened.

**Supersede** when the new decision actually replaces the old one — the original reasoning no longer holds, the mechanism itself changed, or enough of the document's content would need rewriting that patching it in place would obscure rather than preserve the history. Superseding means:

- A **new ADR**, next sequential number, is written in full.
- The new ADR's frontmatter carries **`Supersedes: ADR-NNN`**.
- The old ADR's `Status` line is edited to **`Superseded by ADR-NNN`** — its body is otherwise left alone, as a historical record of what was believed and why, at the time.
- The old ADR is never deleted, renumbered, or rewritten to look like it agreed with the new one all along.

**Rule of thumb when you're unsure which applies:**
- if you can describe the change as *"one more thing to know,"* it's an amendment. 
- If you can't describe the new decision without contradicting a sentence in the old one's `Decision` section, it's a supersession.

---

## RFCs

### When to open one

A change that's non-trivial enough to want written-down reasoning _before_ touching files — especially a multi-step migration or restructuring where you want phases you can commit against individually, not a single decision you can state in a paragraph *(that's just an ADR).* If you already know the answer and there's one obvious path, skip the RFC and write the ADR directly once it's done.

### Working with one

An RFC is a thinking tool, not a polished deliverable — the template's own header comment says as much. Fill in `Problem`, `Proposed Solution`, `Alternatives Considered`, and `Trade-offs` honestly, including the `Open questions` you don't yet have answers to. It's fine for an RFC to sit in `Under Review` while you work through open questions in conversation or in practice, before touching the `Decision` section.

### Closing one

An RFC resolves one of two ways:

- **Accepted** —:
    - fill in the `Decision` section (`Outcome`, `Reason`), then write the ADR(s) that record what was actually decided, and link back to them from the RFC's `ADR:` line.
    - A single RFC covering several related decisions *(e.g. a restructuring touching namespace, profile mechanism, and constants)* is allowed to spawn more than one ADR — don't force everything into one document just because it started as one RFC.
      
- **Rejected** —:
    - fill in `Decision` with `Outcome: Rejected` and the reason.
    - The RFC is **not deleted**.
    - A rejected RFC is a record of a path considered and not taken, which is exactly the kind of thing a future session benefits from not re-discovering the hard way.

An RFC never gets edited after its `Decision` section is filled in, aside from fixing the ADR link if a later ADR further revises the outcome — *at that point the later ADR carries the `Supersedes`/amendment relationship, not the original RFC.*

---

## Runbooks

### When to write one

A procedure that either:
1. Recurs often enough that re-deriving the steps each time is wasted effort.
2. Or is risky/unforgiving enough *(data migration, a service with real downtime cost)* that improvising it live is the wrong time to first think it through. If a procedure is genuinely one-off, it doesn't need a runbook — *write it in the journal instead.*

### Relationship to ADRs

- A runbook **operationalizes** a decision; it doesn't argue for one.
- If a runbook step needs justifying *("why do we do it this way"),* that justification belongs in the ADR it's linked from, not inline in the runbook — *runbooks stay terse and imperative on purpose (see the template's own framing note: "for DOING, not for UNDERSTANDING").*

### Upkeep discipline

The `Last verified` date in the frontmatter is not decorative — a runbook that hasn't been re-verified against the current state of the repo should be treated with suspicion, not blind trust, the next time it's needed.

Update the date whenever you actually run the procedure and confirm it still works as written, even if nothing in the document itself changed.

---