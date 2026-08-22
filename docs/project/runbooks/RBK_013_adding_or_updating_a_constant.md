# Runbook: Adding or Updating a Constant

**Last verified:** 2026-08-22
**Host:** `cypher-nixos`
**Module:** `src/config/constants/`
**Trigger:** Reactive
**Estimated time:** ~10 minutes

---

## When To Use This Runbook

You're introducing a new hardcoded value that should be treated as a constant *(a path, a device name, an identifier reused across Nix modules and/or shell scripts),* or changing the value of an existing one.

## Prerequisites

- Confirm the value is genuinely shared across more than one consumer *(multiple Nix modules, or Nix + a script)* — a value used in exactly one place doesn't need to go through `constants.*`; it can stay local to that module.

## Procedure

### Step 1 — Declare the option

Add the constant to `src/config/constants/options.nix`, camelCase per [naming](../../contributing/conventions/naming.md).

### Step 2 — Set its value

Set it in `src/config/constants/system.nix`, or override per-host if the value should differ across hosts.

### Step 3 — Confirm it regenerates in the JSON file

```bash
nixos-rebuild build --flake .#cypher-nixos
cat /etc/cypher-os/constants.json
```

**Expected output:** the new/changed key appears in the generated JSON, with the exact same key name as the Nix option (no re-casing).

### Step 4 — Update any scripts referencing the old hardcoded value

```bash
grep -rn "<old-hardcoded-value>" scripts/
```

Replace direct references with a read from `/etc/cypher-os/constants.json` (e.g. via `jq -r .<key> /etc/cypher-os/constants.json`) rather than hardcoding the new value in the script too — that reintroduces the duplication this mechanism exists to remove.

### Step 5 — Rebuild and verify

```bash
nixos-rebuild switch --flake .#cypher-nixos
```

**Expected result:** system rebuilds cleanly; scripts touched in Step 4 read the updated value from the generated file.

---

## Troubleshooting

### A script still shows the old value after rebuild

Check it wasn't hardcoded in a shell variable at the top of the script instead of reading `constants.json` live — this is the exact class of bug `constants.*` was introduced to eliminate; see the `homeDirectory`/ `username` history in [ADR_014](../decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md) for why independence between related constants matters here.

## Rollback

Revert the option/value change in `src/config/constants/`; revert any script edits from Step 4 back to their prior hardcoded values if needed.

## Related

- ADR: [ADR_023](../decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md), [ADR_014](../decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md)

---

<!--
METADATA
Created: 2026-08-22
Updated: 2026-08-22
Tested by: Cypher Whisperer
-->