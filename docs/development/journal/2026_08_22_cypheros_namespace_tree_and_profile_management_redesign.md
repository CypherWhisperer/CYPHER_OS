# 2026_08_22 CypherOS Namespace, Tree, and Profile-Management Redesign

**Date:** 2026-08-22
**Duration:** ~1 long session *(exact clock time not tracked — design/discussion only, no implementation yet)*
**Repos touched:** CypherOS *(docs only)*
**Modules touched:** none — no `.nix` files changed this session; deliverables are all under `docs/`
**Phase:** 

---

## What I Worked On

Opened this session with five architectural questions about CypherOS that had been nagging:
1. what packages exist and how they're grouped.
2. what the optimal namespace/gating design is.
3. how to guarantee deterministic config.
4. how to manage user/profile state in one unified place.
5. and how to stop hardcoding constants throughout the flake and scripts. 

Explicitly did not want to jump to code — wanted to understand the design before touching anything, and to lock decisions in writing first.

## What Got Done
  
- Worked out the actual mechanism for unified profile management:
    - A single `profile.active` enum *(replacing the old two-boolean design),* propagated to Home Manager via `osConfig` when nested, with an explicit fallback for the standalone/non-NixOS-lens case.
    - Same shape reused for a new `lens.current` signal, which also fixes the long-standing fonts `hm.nix`/`system.nix` duplication.
  
- Locked the gating convention:
    - Leaves never check the active profile themselves — only `enable && parent.enable`.
    - All profile-conditional defaults live in one place (`src/profile/{system,hm}.nix`), authored once.
  
- Reworked the repo tree and namespace tree together, category by category:
    - `de`/`dm`/`shell`/`fonts`/`xdg` promoted to top-level (neither `pkgs` nor `system`, on purpose); `security`/`privacy` split out of the old `apps.common.security`; `core`/`cli` split out of the old flat CLI toolbelt; `utils` given a home; `arduino` and `virtualisation` placed; devShells restricted to CLI/TUI-only, GUI always through hm/system.
  
- Fixed the aggregator asymmetry — HM side already had one (`modules/home/default.nix`), system side didn't. Added `src/system/default.nix` to match.
  
- Reviewed the actual contents of ADR-001 and ADR-005 against everything above and worked out, concretely, which one gets superseded *(ADR-001 — too much of its content actually changes)* and which gets amended *(ADR-005 — one wrong sentence, everything else still holds).* That distinction didn't exist as a documented convention before this session — wrote it up properly in [templates](../../contributing/conventions/templates.md) since I'd been implicitly assuming ADRs only ever get superseded, never amended.
  
- Wrote [naming](../../contributing/conventions/naming.md) from scratch (genuine gap — file existed but not written officially).
  
- Produced:
    1. [ADR_023](../../project/decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md) (namespace/profile redesign, supersedes [ADR_001](../../project/decisions/ADR_001_cypher-os_namespace_design.md))
    2. [ADR_024](../../project/decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md) (the `osConfig` SSOT mechanism — decided this earned its own ADR rather than being folded into 023 or the ADR-005 amendment, since it's a reusable cross-context mechanism, not a namespace or file-layout decision)
    3. the [ADR_005](../../project/decisions/ADR_005_module_architecture.md) amendment
    4. [RFC_001](../../project/rfcs/RFC_001_cypherOS_repo_and_namespace_restructure_implementation_plan.md) (phased implementation plan)
    5. a tree/changes reference doc
    6. and six runbooks (RBK-009 through RBK-014) covering the recurring procedures this redesign creates:
        1. adding a category.
        2. adding a leaf.
        3. adding an overlay.
        4. adding a devshell.
        5. adding a constant.
        6. onboarding a new host/lens.

## Key Decisions Made

All of the substantive decisions from this session are already captured in ADR-023 and ADR-024 rather than sitting only here.

## Where I Got Stuck

N/A

## What I Learned

The `osConfig` special-arg only exists when Home Manager is evaluated nested inside `nixosSystem` — it's not available to a standalone `homeManagerConfiguration` at all.

Obvious in hindsight, but it's the fact that actually unlocks true single-source-of-truth profile management for the NixOS-integrated host, while explaining why the non-NixOS lenses (Arch, Debian, Fedora, openSUSE) can never fully escape some duplication — there's no shared evaluation for them to read from.

That distinction did a lot of work this session; several open questions dissolved once it was named explicitly.

## Open Questions

- Whether `keepassxc` really belongs under the new `security` category or would sit better under `privacy` — left as-is under `security` for now since it's grouped with the rest of the audit/recon toolkit functionally, but it's a genuine borderline case worth a second look later.
  
- The actual `pkgs.*` list *(what packages exist today, mapped onto the new tree)* was explicitly deferred to a dedicated session — namespace/tree shape only, this time.

## Next Session

Work through RFC_001 phase by phase on a dedicated refactor branch — Phase 0 (branch cut) through Phase 7 (verification + the one and only `switch`).

---

<!--
Commit range:
CypherOS: (docs-only session — no commits yet; will fill in once RFC-001 Phase 0 branch is cut)
-->