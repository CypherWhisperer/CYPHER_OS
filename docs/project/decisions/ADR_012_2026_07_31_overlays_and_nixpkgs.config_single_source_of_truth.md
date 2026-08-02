# ADR_012_2026_07_31: Overlays and `nixpkgs.config` — _Single Source of Truth_

**Date:** 2026-07-31
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

Prior to this change, `flake.nix` instantiated `pkgs` twice, independently: once via a top-level `let pkgs = import nixpkgs { ... overlays = [...]; };` consumed only by `homeConfigurations`, and once via a `nixpkgs.overlays` / `nixpkgs.config.allowUnfree` module block inside `nixosConfigurations.cypher-nixos`'s `modules` list, consumed by both the NixOS system and (via `useGlobalPkgs = true`) the NixOS-integrated Home Manager path. 

These two overlay lists had drifted: the module-level list included `claude-desktop.overlays.default`, the top-level `let` did not, and `hosts/nixos/configuration.nix` additionally carried its own separate, third copy of `nixpkgs.config.allowUnfree`/`permittedInsecurePackages`/`overlays` that was missing `nur.overlays.default` relative to the flake-level list.

This surfaced as a concrete bug during [ADR_011_2026_07_31](ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md): `home-manager switch --flake .#cypher-whisperer@cypher-nixos` *(the standalone path)* failed with `error: attribute 'claude-desktop' missing`, while `nixos-rebuild switch` succeeded, because only one of the two `pkgs` instances carried the overlay providing that package.

The immediate workaround — *duplicating the overlay into `modules/home/default.nix` as well* — fixed the symptom but added a third copy rather than removing the duplication.

## Decision

Overlays and `nixpkgs.config` *(`allowUnfree`, `permittedInsecurePackages`)* are declared exactly once, in `flake/nixpkgs-config.nix`, as a function of `inputs` returning `{ overlays = [...]; config = {...}; }`. 

Both `flake/hosts.nix` *(feeding the NixOS module's `nixpkgs.overlays`/`nixpkgs.config`)* and `flake/home-configurations.nix` *(feeding the standalone `pkgs` instantiation)* consume this same value via `flake/default.nix`. 

All other copies — the top-level `let pkgs` overlay list, the `nixosConfigurations` module-inline overlay block, `hosts/nixos/configuration.nix`'s separate copy, and the workaround duplication in `modules/home/default.nix` — are removed.

## Reasoning

Two independent `pkgs` instantiations feeding two independently-runnable config-application paths *(`nixos-rebuild switch` and standalone `home-manager switch`)* will silently diverge unless a change to one is mechanically guaranteed to reach the other.

Manual duplication does not provide that guarantee — it produced this exact bug once already, and every future overlay addition carried the same risk of being added to only one of *(at the time)* three copies.

A single binding, imported by both consumers, converts *"remember to update both"* into *"there is only one to update."*

## Alternatives Considered

### Leave the duplication, add a checklist/comment reminding future edits to update both places

This is roughly what existed before the fix (a code comment in `flake/home-configurations.nix` documenting the exact "must be imported in every context" pattern for HM module flakes, written after diagnosing the `catppuccin` version of this same problem).

Rejected as insufficient:
- the comment existed, described the exact failure mode, and the `claude-desktop` bug happened anyway.
- A convention that has already failed to prevent a recurrence of the class of bug it documents is not a fix.

### Have `homeConfigurations` derive its `pkgs` from `nixosConfigurations.cypher-nixos.pkgs` directly, rather than a shared upstream binding

Would guarantee identical overlays by construction rather than by discipline. 

Rejected for this codebase:
- it would create an evaluation dependency from the standalone HM path onto the full NixOS system closure, which is heavier than necessary and would complicate ever adding a `homeConfigurations` entry for a genuinely non-NixOS host *(Arch/Debian/Fedora/openSUSE lenses),* where no `nixosConfigurations` entry exists to derive from.

A shared upstream value both consume independently keeps the paths structurally symmetric.

## Consequences

**Positive:**

- One list to update when adding a new overlay; both `nixos-rebuild switch` and standalone `home-manager switch` see it identically
- Closes the exact `claude-desktop` bug class, not just the one instance of it
- `hosts/nixos/configuration.nix`'s previously-drifted third copy (missing `nur.overlays.default`) is also resolved as a side effect

**Negative / Trade-offs:**

- One more level of indirection to trace when debugging an overlay-related evaluation error *(`flake/nixpkgs-config.nix` → `flake/default.nix` → consumer),* versus previously being able to find the relevant list inline at each call site
  
- `nixpkgs.config` items that are genuinely host-specific in the future *(were CypherOS to add a host needing different `permittedInsecurePackages`, for example)* don't have an obvious per-host override point in the current single-function design and would need one added

**Neutral / Operational:**

- `modules/home/default.nix` no longer sets `nixpkgs.overlays`, `nixpkgs.config.allowUnfree`, or `nixpkgs.config.permittedInsecurePackages` — *it reverts to a pure HM-module-tree entry point, matching its role in both evaluation contexts*

---