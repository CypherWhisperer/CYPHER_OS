# 2026_09_11 CypherOS Namespace, Profile & Constants Implementation

**Date:** 2026-09-11
**Duration:** ~9 days, daily *(Sept 2 – Sept 11)*
**Repos touched:** CypherOS
**Modules touched:** 
1. `src/*`,
2. `flake/{hosts,home_configurations,default}.nix`
**Phase:** RFC_001 Phase 3–5 (profile/constants scaffolding through category migration)

---

## What I Worked On

Implementation of the decisions made in the [2026_08_22 session](2026_08_22_cypheros_namespace_tree_and_profile_management_redesign.md) — this session is the *doing*, not the deciding.

Built out `src/profile/*` and `src/config/constants/*` per ADR-023/ADR-024, then worked through Phase 5's category-by-category migration from `modules/*` to `src/*`, converging on and refining conventions along the way.

---

## What Got Done

- `src/profile/{options,system,hm}.nix` — profile/lens SSOT, `osConfig ? null` fallback, `_module.args` exposing `cypherOsProfile`/`cypherOsLens`
  
- `src/config/constants/{options,system,hm}.nix` + `values.nix` — three-bucket variance scheme ***(static-invariant, derived-invariant, machine-variant)***; dual JSON generation (`/etc/...`, `~/.config/...`); `values.nix` as a plain-data escape hatch for flake-level glue code that can't reach `_module.args`
  
- Migrated categories: 
    1. every module under previous `modules/*` to `src/*`
    2. `src/theme/` — new category, Catppuccin as the sole engine today, shape reserved (not built) for a future second engine
    3. New categories under `src/pkgs/`: `{creativity,communication,media,networking,noeta}`
      
- Namespace move: `pkgs.editor.*` → `pkgs.dev.ide.*` for full IDEs; `vim`/`zettlr` stay under `editor.*`. VSCode's own modularization (extensions tree, shared-settings accumulator for Cursor/Antigravity forks).
  
- `flake/{hosts,home_configurations,default}.nix` fully wired against `values.nix`
  
- Conventions established/amended: `gating_and_assertions.md` (§1–§14), `profile_defaults.md`, `constants.md`, `shared_config_accumulation.md`; `naming.md` host/machine/lens terminology; ADR_023 amended twice *(gui pattern + namespace-tree-is-illustrative; editor→dev.ide split);* RFC_001 amended *(Phase 5 execution checklist, pull-based defaults correction)*
  
- `src/_templates/{options,hm_system,defaults}.nix` — reusable scaffolding, refined through actual use
  
- `RBK_009`/`RBK_010` updated for the pull-based pattern and `defaults.nix` centralization; `RBK_015` (profile/lens membership audit) drafted; `docs/project/profile_membership.md` created

---

## Key Decisions Made

1. **Pull-based profile/lens defaults, not push-based.:**
    - `src/profile/*` and `src/config/constants/*` are signal-only — never reference another category's namespace.
    - Each category pulls `cypherOsProfile`/`cypherOsLens`/`cypherOsConstants` and owns its own defaults.
    - Retires the pre-refactor `modules/profile/{default,system}.nix` hub pattern.
    - See [`profile_defaults.md`](../../contriburing/conventions/profile_defaults.ms).
      
2. **`<category>.gui` as a standard sub-branch:**
    - for both-profile categories with a partial desktop-only GUI subset — avoids gating the whole category behind `profile.active == "desktop"` (wrongly drops server-valid content) or collapsing multiple GUI tools into one switch. 
      
3. **`defaults.nix` centralization:**
    - For any category with both `hm.nix` and `system.nix` — defaults/assertions expressible purely via `cfg.*`/`cypherOsProfile`/`cypherOsLens`/`lib` don't need duplicating across both graphs.
      
4. **Internal accumulator options:**
    - (`shared_config_accumulation.md`) for multi-leaf-contributed generated artifacts ***(VSCode's settings.json shared with Cursor/Antigravity forks)*** — attrs-typed option, deep-merged across leaves, written out exactly once.
      
5. **RFC_002 opened (incomplete, deliberately):**
    - Narrow scope, `@data` subvolume keep-vs-drop only.
    - Leaning toward *keep*, pending the full mount-implementation session.
    - To be extended to general BTRFS-related work for CypherOS.
      
6. Namespace-dependent leaves (VSCode extension ↔ toolchain state) mirror via `mkDefault`, never gate or assert on the external condition — *legitimate independent states, not invalid ones.*

---

## Where I Got Stuck

Several real bugs caught via critique before they hit a build — worth remembering the *shapes*, since they're likely to recur:
- Re-deriving the `osConfig ? null` fallback locally instead of consuming the centralized `cypherOsProfile` arg (GNOME's `hm.nix`, twice)
  
- Spurious `config.` prefix on an item already inside `config = lib.mkMerge [ ... ]`

- `lib.mkDefault` used as an attribute *name* instead of the function it is

- Writing through a `let`-bound `cfg` read-alias (`cfg.zsh.enable = ...` doesn't write to the real option path)

- `flake/hosts.nix` double-nesting `nixosConfigurations.nixosConfigurations.<host>` — imported file pre-labeled its own return value, then the importer labeled it again

- `lib.removePrefix`'s silent-no-match-returns-unchanged behavior, in the Obsidian vault-path derivation — converted to a loud assertion

---

## What I Learned

Built a working mental model of `_module.args`, `evalModules`, `nixosSystem`, the nested-vs-standalone HM evaluation split, and why `osConfig` exists at all ***(two independent `evalModules` calls can't share a resolved value, only a declared schema).*** Still want the full structured deep-dive.

---

## Open Questions

- RFC_002 (`@data` keep/drop) not finalized — *pending the full mount-implementation session*
- `DE_FILES/SHARED/*` pattern confirmed obsolete, not yet cleaned up
- Obsidian vault-path fix (symlink-based) deferred to the same session — `target` only accepts `$HOME`-relative paths, no absolute-path escape
- `docs/project/profile_membership.md` structure exists; not yet populated against the real tree

---

## Next Session

Immediate: troubleshooting sub-session — iterating `nixos-rebuild build`/`home-manager build` against everything above until clean. Prompt below.

After that: RFC_001 Phase 6 (docs restructuring to mirror `src/*`) to close out RFC_001 fully.

Separately, on the agenda: the BTRFS/`@data` mount session — `@data` + `@docker-data` subvolumes, `DE_FILES` flattening, Obsidian vault symlink fix, setup script updates, `disko` evaluation, promoting `guide_btrfs_snapshots.md` to a convention/runbook. See [RFC_002](../../project/rfcs/RFC_002_data_subvolume_retention_decision.md) (incomplete) as the anchor for that session's scope.

---

<!--
Commit range (fill in after session):
CypherOS: [fill in] → [fill in]
-->