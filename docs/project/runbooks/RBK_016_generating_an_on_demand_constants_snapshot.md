# Runbook: Generating an On-Demand Constants JSON Snapshot

**Last verified:** 2026-09-11
**Host:** `cypher-nixos` (and any standalone lens)
**Module:** `.local/constants.json` (repo-local, gitignored), `flake/apps/dump-constants.nix` or equivalent flake app
**Trigger:** Reactive
**Estimated time:** ~2 minutes

---

## When To Use This Runbook

You need the current, evaluated `cypher-os.constants.*` values *before* any host has been switched — a bootstrap/initial-install script, or a fast dev-time check — without waiting on a full `build`/`switch` and without depending on `/etc/cypher-os/constants.json` or `~/.config/cypher-os/constants.json` existing (both are deploy-time artifacts; this isn't).

## Prerequisites

- A checked-out flake source tree — no built or switched system required.
- `nix` with flakes enabled.

## Procedure

### Step 1 — Run the dump app

```bash
nix run .#dump-constants
```

Expected output: `.local/constants.json` created/overwritten at the repo root, containing the full evaluated `cypher-os.constants` attrset as JSON.

If this fails: confirm the app is actually wired in `flake/default.nix`'s `apps.<system>` output — see [constants.md](../../contributing/conventions/constants.md) §2.

### Step 2 — Consume it

```bash
jq -r '.<key>' .local/constants.json
```

Use in bootstrap/install scripts exactly as any other JSON read — no `/etc` or `$HOME` dependency.

### Step 3 — Re-run whenever source changes

No automatic regeneration — re-run Step 1 after any `cypher-os.constants.*` edit you need reflected. Unlike the deployed copies, nothing regenerates this on `switch`/activation.

---

## Troubleshooting

### `.local/constants.json` is stale relative to source

Expected — this file has no activation-time regeneration hook by design (see Step 3). Re-run.

### Values differ from `/etc/cypher-os/constants.json`

Only expected if source has changed since the last `switch` — the deployed file only updates on activation; this one reflects source at time of `run`, not the running system.

## Rollback

Delete `.local/constants.json` — gitignored, no repo state affected.

## Related

- Convention: [constants.md](../../contributing/conventions/constants.md)
- Runbook: [RBK_013](RBK_013_adding_or_updating_a_constant.md)

---

<!--
METADATA
Created:    2026-09-11
Updated:    2026-09-11
Tested by:  Cypher Whisperer
-->