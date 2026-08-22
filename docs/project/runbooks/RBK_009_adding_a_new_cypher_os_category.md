# Runbook: Adding a New `cypher-os` Category

**Last verified:** 2026-08-22
**Host:** `cypher-nixos`
**Module:** `src/{pkgs,system}/<new-category>/`
**Trigger:** Reactive
**Estimated time:** ~20 minutes

---

## When To Use This Runbook

You're introducing an entirely new top-level *(or `pkgs`/`system` nested)* category — something with no existing `options.nix` anywhere in the tree — per the scaffold in [ADR_005](../decisions/ADR_005_module_architecture.md) and the tree shape in [ADR_023](../decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md).

## Prerequisites

- The category's namespace path decided (`cypher-os.pkgs.<name>` or `cypher-os.system.<name>`, or a top-level sibling per the `de`/`dm`/ `shell`/`fonts`/`xdg` exception) — *see [naming](../../contributing/conventions/naming.md) for casing.*
- Know which evaluation context(s) the category needs: HM only, system only, or both.

## Procedure

### Step 1 — Create the category directory and `options.nix`

```bash
mkdir -p src/<tree-location>/<name>
```

Declare the category's `enable` and any known leaf `enable` options in `options.nix`. No `config` block here — *options.nix stays declarations-only.*

Expected output: file exists, `nix flake check` still passes *(no config references the new options yet, so nothing can be wrong).*

### Step 2 — Create `default.nix` (HM shim)

Imports `./options.nix` and `./hm.nix` *(omit `hm.nix` from imports if the category has no HM-level config at all).*

### Step 3 — Create `hm.nix` and/or `system.nix` as needed

Each file: `imports = [ ./options.nix ];` at the top, then a `config = lib.mkIf config.cypher-os.<path>.enable { ... }` block. Never mix `home.*`/`dconf.*` into `system.nix`, or `services.*`/`environment.*` into `hm.nix`/`default.nix`.

### Step 4 — Register in the relevant aggregator(s)

Add the new directory to `src/home/default.nix`'s imports *(if it has HM config)* and/or `src/system/default.nix`'s imports *(if it has system config).*

Expected output: `nix flake check` passes; the new options resolve in `nix eval .#nixosConfigurations.cypher-nixos.config.cypher-os.<path>`.

### Step 5 — Add profile defaults, if any

If the category *(or specific leaves within it)* should default on/off per profile, add the `lib.mkDefault` line to `src/profile/{system,hm}.nix` — never inside the category's own files. See [RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md) for the leaf-level version of this step.

### Step 6 — Verify

```bash
nixos-rebuild build --flake .#cypher-nixos
home-manager build --flake .#cypher_whisperer@cypher-nixos
```

Expected result: both build clean with no evaluation errors.

---

## Troubleshooting

### "attribute '`cypher-os.<path>`' is missing"

The consuming file didn't import `options.nix` in its own evaluation context — check that both `default.nix` (HM) and `system.nix` (NixOS), if both exist, import it independently.

### Home Manager build fails with an unrecognized attribute *(e.g. `services.*`)*

`system.nix` content leaked into `default.nix` or `hm.nix`. Move it out — see [ADR_005](../decisions/ADR_005_module_architecture.md)'s four invariants.

## Rollback

Delete the new category directory and revert the aggregator import(s) added in Step 4 — nothing outside the new directory was touched if the prior steps were followed in order.

## Related

- ADR: [ADR_005](../decisions/ADR_005_module_architecture.md), [ADR_023](../decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md)
- Runbook: [RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md)

---

<!--
METADATA
Created: 2026-08-22 
Updated: 2026-08-22
Tested by: Cypher Whisperer
-->