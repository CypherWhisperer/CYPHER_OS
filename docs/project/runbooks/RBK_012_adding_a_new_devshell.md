# Runbook: Adding a New DevShell / DevEnv Template

**Last verified:** 2026-08-22
**Host:** `cypher-nixos`
**Module:** `flake/devshells/` (flake-level) or `src/pkgs/devshells/` (category)
**Trigger:** Reactive
**Estimated time:** ~15 minutes

---

## When To Use This Runbook

Adding a new environment for hacking on CypherOS itself (`flake/devshells/`) or a new templated project `devenv` users of the system can opt into (`cypher-os.pkgs.devshells`, e.g. the nixamp LAMP devenv).

## Prerequisites

- **CLI/TUI tooling only.** 
    - Per this session's decision, devShells never carry GUI applications — they don't register `.desktop` entries, XDG MIME associations, or autostart, so a GUI package gains nothing by being in a devShell versus installed normally through `hm`/`system`, and loses menu presence entirely.
    - If the thing you're adding is a GUI app, it belongs in a `pkgs/` category instead — stop and use [RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md).

## Procedure

### Step 1 — Determine which devShell layer this belongs to

Flake-level (`flake/devshells/<name>.nix`) if it's for developing CypherOS itself.

Category-level (`src/pkgs/devshells/<name>.nix`) if it's a reusable template for a _type of project_ (a language, a stack) that any host's user might want to drop into a project directory.

### Step 2 — Write the shell definition

```nix
{ pkgs, ... }:
pkgs.mkShell {
  packages = with pkgs; [
    # CLI/TUI only — compilers, linters, formatters, LSPs, build tools
  ];
}
```

### Step 3 — Wire it in

**Flake-level:** add to the `devShells.<system>` attrset in `flake/devshells/default.nix`.

**Category-level:** add its `enable` leaf to `src/pkgs/devshells/options.nix` and the corresponding install logic to `hm.nix`, following the standard leaf pattern ([RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md)).

### Step 4 — Verify

```bash
nix develop .#<name>          # flake-level
nix flake check               # category-level, after rebuild
```

**Expected result:** shell drops you into an environment with exactly the listed CLI tools on `$PATH`; no GUI package is present in either case.

---

## Troubleshooting

### A GUI package was added by mistake

Remove it from the devShell definition and install it through the appropriate `pkgs/` category instead — see [RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md).

## Rollback

Remove the shell file and its wiring from the relevant `default.nix`/ `options.nix`.

## Related

- Runbook: [RBK_010](RBK_010_adding_a_leaf_to%20an_existing_category.md)
- Module doc: `docs/source_docs/flake/devshells.md` (pending)

---

<!--
METADATA
Created: 2026-08-22
Updated: 2026-08-22
Tested by: Cypher Whisperer
-->