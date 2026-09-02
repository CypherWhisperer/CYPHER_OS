# RFC_001: CypherOS Repo/Namespace Restructure — Implementation Plan

**ID:** RFC_001
**Date:** 2026-08-22
**Status:** Accepted → [ADR_023](../decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md), [ADR_024](../decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)
**Author:** CypherWhisperer

---

## Problem

The architectural decisions locked in 2026_08_22 session (namespace redesign, profile/lens SSOT mechanism, category promotions and splits, constants management, aggregator symmetry) touch nearly every part of the existing `flake/`, `hosts/`, and `modules/` trees at once.

Implemented as one undifferentiated pass, this is high-risk:
- A broken intermediate state is hard to bisect, and there's no natural point to stop, verify, and commit.
- This RFC exists to sequence the work into phases that are each independently buildable, verifiable, and committable.

## Proposed Solution

A dedicated refactor branch, worked in the phases below, each ending in a `nix flake check` *(and, where relevant, a `nixos-rebuild build` / `home-manager build` dry run — **not** `switch`, until the final phase)* before committing. Each phase's commit message is suggested, not mandatory.

### How It Works

**Phase 0 — Preparation**

- Create a refactor branch (e.g. `refactor/namespace-and-tree-redesign`) off current `master`.
- Copy `flake.lock` aside for comparison; this refactor should not need to change any flake input's pinned revision.
- Commit: `chore: branch cut for namespace/tree restructure`

**Phase 1 — `flake/` boundary adjustments**

- Give `devshells` its own directory at `flake/devshells/` *(flake-level `devShells` output)* — no behavior change, pure file move.
- Verify: `nix flake check`
- Commit: `refactor(flake): give devshells its own directory`

**Phase 2 — `src/system/` aggregator scaffold**

- Create `src/system/default.nix`, mirroring `src/home/default.nix`'s aggregator shape (imports every system-category `default.nix`).
  
- Move `hosts/nixos/boot.nix` → `src/system/boot/` (policy content only; `hosts/nixos/hardware-configuration.nix` stays put, machine-generated).
  
- Update `hosts/nixos/configuration.nix` to import only: hardware config, the *(not-yet-created)* `profile.nix`, and `src/system` — do **not** yet remove the old flat `system.nix` imports; leave both wired in parallel for this phase so the system still evaluates.
  
- Verify: `nixos-rebuild build --flake .#cypher-nixos`
- Commit: `refactor(system): introduce src/system aggregator, move boot.nix`

**Phase 3 — Profile and lens SSOT module**

- Create `src/profile/{options,system,hm}.nix` per ADR-023/ADR-024:
    - `options.nix` declares `cypher-os.profile.active` and `cypher-os.lens.current`; `hm.nix` implements the `osConfig ? null` fallback pattern from ADR-024.
      
- Create the host-owned `hosts/nixos/profile.nix` setting `cypher-os.profile.active = "desktop"; cypher-os.lens.current = "nixos";` and import it from `configuration.nix`.
  
- **We  don't yet** move any category's `mkDefault` cascade into `src/profile/{system,hm}.nix` — *that happens per-category in Phase 5, to keep this phase's diff reviewable on its own.*
  
- Verify: `nixos-rebuild build --flake .#cypher-nixos` and `home-manager build --flake .#cypher_whisperer@cypher-nixos`
- Commit: `feat(profile): introduce profile.active / lens.current SSOT`

**Phase 4 — Constants module**

- Create `src/config/constants/{options,system}.nix` declaring `cypher-os.constants.{username,homeDirectory,primaryDisk,vaultPath}`.
  
- Add the `environment.etc."cypher-os/constants.json"` generation *(per ADR-023's constants section)* in `system.nix`.
  
- We **don't** yet rewrite existing scripts to consume the generated file — that's a mechanical follow-up once the file's presence is verified on a built system; track it as a checklist item, not part of this phase's verification gate.
  
- Verify: `nixos-rebuild build --flake .#cypher-nixos`
- Commit: `feat(constants): introduce cypher-os.constants.* and generated JSON`

**Phase 5 — Category promotions and splits** Each of the following is independently commit-able; do them as separate commits within this phase rather than one large diff:

1. Promote `de`, `dm`, `shell`, `fonts`, `xdg` to top-level categories (they largely already are at the file level — this is primarily a namespace-path change, `cypher-os.<name>.*` rather than any nested form).
   
2. Apply the fonts `lens.current` fix from ADR-024 — HM installs the full font set only when `lens.current != "nixos"`.
   
3. Split `apps.common.security` into `src/security/` and `src/privacy/`, each with its own `options.nix`. Give `wireshark`/`keepassxc` their own leaf files and enable flags; move their profile-conditional defaults into `src/profile/hm.nix`.
   
4. Split `apps/cli/hm.nix` into `src/pkgs/core/` (ungated toolbelt) and `src/pkgs/cli/` (existing individually-toggleable TUI tools, unchanged in behavior).
   
5. Create `src/pkgs/utils/` for `disk-utils`.
   
6. Move `arduino` under `src/pkgs/dev/arduino/`; move `virtualisation` under `src/system/virtualisation/`.

Verify after **each** sub-step: `nixos-rebuild build --flake .#cypher-nixos` and `home-manager build --flake .#cypher_whisperer@cypher-nixos`.

**Phase 6 — Documentation restructuring**

- Restructure `docs/source_docs/` to mirror the new repo tree (`flake/`, `hosts/`, `src/{profile,config,pkgs,system,...}`).
  
- Cross-link the new/amended ADRs (023, 024, the ADR-005 amendment) from any `source_docs` pages covering the modules they touch.
  
- Commit: `docs: restructure source_docs to mirror new tree`

**Phase 7 — Verification and cutover**

- Full `nix flake check`.
- `home-manager build --flake .#cypher_whisperer@cypher-nixos` (standalone path) and `nixos-rebuild build --flake .#cypher-nixos` (integrated path), both clean.
  
- `nixos-rebuild switch --flake .#cypher-nixos` — this is the first `switch` of the entire refactor; everything prior stayed at `build` only.
  
- Remove any parallel/legacy imports left in place from Phase 2 once the switch succeeds and the system is confirmed stable across a reboot.
  
- Commit: `refactor: cutover to restructured namespace and tree` *(tag or note in the journal entry that closes this session).*

## Alternatives Considered

### One large commit for the entire restructure

**Rejected:**
- a single all-at-once diff across namespace, profile mechanism, and category splits is very hard to bisect if `nixos-rebuild switch` fails partway, and gives no natural checkpoint to stop at if something needs reconsideration mid-implementation.

### Category-first ordering *(do Phase 5 before the profile/constants scaffolding)*

Considered, since category splits are the most numerous individual changes. 

**Rejected:**
- in favor of scaffolding the SSOT mechanism (profile, lens, constants) first, because several of the category-split steps in Phase 5 (the fonts fix, the security/privacy profile defaults) directly depend on `src/profile/hm.nix` and `cypher-os.lens.current` already existing — doing categories first would mean touching them twice.

## Trade-offs

**Gains:**

- Every phase ends in a state that at least type-checks and dry-run builds, giving a real bisection point if something breaks later.
- `switch` (the only operation with real downtime/rollback cost) happens exactly once, at the end, after every other change has already been validated at `build` level.

**Costs / Risks:**

- Phase 2 deliberately leaves both old and new system imports wired in parallel for one phase — a reader of the repo mid-refactor will see a temporarily redundant import list. This is intentional and temporary, not a leftover to be confused for the final state.
- The scripts-consume-the-JSON-file follow-up in Phase 4 is explicitly deferred past this RFC's verification gate — track it separately so it doesn't get silently dropped.

**Open questions:**

- Whether Phase 6 (docs restructuring) should happen before or after Phase 7's `switch` — as written it's before, on the reasoning that docs should already reflect the target state before the live system commits to it, but this is a preference call, not a hard constraint.

---

## Decision

**Outcome:** Accepted
**Reason:** Phased plan reviewed and approved as the working sequence for the restructure; phases map directly to the milestone/commit granularity requested for the refactor branch.
**ADR:** [ADR_023](../decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md), [ADR_024](../decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)

---

<!-- METADATA Opened: 2026-08-22 Resolved: 2026-08-22 -->