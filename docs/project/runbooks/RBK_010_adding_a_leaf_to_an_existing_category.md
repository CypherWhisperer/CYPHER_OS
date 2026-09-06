# Runbook: Adding a Leaf to an Existing Category

**Last verified:** 2026-09-04
**Host:** `cypher-nixos`
**Module:** `src/{pkgs,system}/<category>/<leaf>.nix`
**Trigger:** Reactive
**Estimated time:** ~10 minutes

---

## When To Use This Runbook

The far more common case than [RBK_009](RBK_009_adding_a_new_cypher_os_category.md) — a new app or tool inside an existing category (a new editor in `src/pkgs/editor/`, a new tool in `src/security/`), where `options.nix` and the aggregator wiring already exist.

## Prerequisites

- The parent category's `enable` option already exists and works.
- Know whether this leaf is profile-conditional *(e.g. GUI-only, defaulting on for `desktop` but not `server`)* or profile-invariant *(true either way)* — this determines whether Step 3 below applies.

## Procedure

### Step 1 — Declare the leaf's option

Add `<leaf>.enable = lib.mkEnableOption "...";` to the category's existing `options.nix`. Do not declare it anywhere else — see [ADR_005](../decisions/ADR_005_module_architecture.md)'s first invariant.

### Step 2 — Create the leaf file

```nix
# src/<category>/<leaf>.nix
{ config, pkgs, lib, ... }:
{
  # no options block — declared in options.nix
  config = lib.mkIf (
    config.cypher-os.<category>.enable &&
    config.cypher-os.<category>.<leaf>.enable
  ) {
    # home.packages / services.<leaf>.enable / etc., matching this category's context
  };
}
```

Import it from the category's `default.nix` *(HM leaves)* or `system.nix` *(system leaves).*

If the parent category has a `defaults.nix` (per [gating_and_assertions.md](../../contributing/conventions/gating_and_assertions.md) §13), add this leaf's default and parent-implies-leaf assertion there instead of in the leaf file itself or duplicating across `hm.nix`/`system.nix`.

### Step 3 — If profile-conditional, add the default in the leaf's own file — not the profile module
​
```nix

# src/<category>/<leaf>.nix (or system.nix, for a system-context leaf)
config.cypher-os.<category>.<leaf>.enable = lib.mkDefault (cypherOsProfile == "desktop");
```
​
`cypherOsProfile` arrives as a module arg (from `src/profile/{system,hm}.nix`'s `_module.args`) — the leaf file takes it as a function parameter alongside `config`/`lib`/etc. `src/profile/*` itself stays profile-*signal*-only and never learns this leaf exists.

If this step feels like it doesn't apply *(the leaf should be on regardless of profile),* skip it — leave the leaf undefaulted, or default it unconditionally in the same file.

Update the profile-membership reference table ([RBK_015](RBK_015_auditing_profile_&_lens_default_membership.md)) if this default is new or changed.

### Step 4 — Verify

```bash
nixos-rebuild build --flake .#cypher-nixos   # if this is a system-context leaf
home-manager build --flake .#cypher_whisperer@cypher-nixos   # if HM-context
```

---

## Troubleshooting

### The leaf installs even with its `enable` left unset

Check the guard in Step 2 — a leaf missing the `parent.enable &&` half of the condition will activate whenever the category itself does, ignoring its own flag.

### Package installs on `server` profile when it shouldn't

The profile-conditional default (Step 3) was skipped, or was written into `src/profile/*` instead of the leaf's own file — *move it back into the leaf.*

## Rollback

Remove the leaf file, its import line, its option declaration, and its `mkDefault` line **from the leaf/category file** if one was added.

## Related

- Runbook: [RBK_009](RBK_009_adding_a_new_cypher_os_category.md)
- Runbook: [RBK_015_auditing_profile_&_lens_default_membership](RBK_015_auditing_profile_&_lens_default_membership.md)
- ADR: [ADR_005](../decisions/ADR_005_module_architecture.md)
- Convention: [profile_defaults](../../contributing/conventions/profile_defaults.md)

---

<!--
METADATA
Created: 2026-08-22
Updated: 2026-09-04
Tested by: Cypher Whisperer
-->