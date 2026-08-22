# ADR_024_2026_08_22: Cross-Context Single-Source-of-Truth via `osConfig`

**Date:** 2026-08-22
**Status:** Accepted
**Deciders:** CypherWhisperer
**Related:**
1. [ADR-023 — Namespace and Profile Redesign](ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md)
2. [ADR-005 — Module Architecture](ADR_005_module_architecture.md)
3. [ADR-011 — Home Manager Stays NixOS-Module-Integrated](ADR_011_2026_07_31_home_manager_stays nixos-module-integrated.md)

---

## Context

ADR-005 solved the problem of _options_ being visible in both the NixOS and Home Manager evaluation contexts *(both graphs import `options.nix`).* It did not solve a related, deeper problem:
- two option trees, evaluated by two separate `lib.evalModules` calls, cannot literally share one _resolved value_ — each graph resolves its own copy, even when both declare the same option path.

This was previously invisible because most `cypher-os.*` options were only ever _read_ within the same graph that declared them. It became visible once the profile mechanism (ADR-023) needed exactly one value — `profile.active` — to be authoritative across both graphs simultaneously, and once the fonts category was found to be manually duplicating its package list between `hm.nix` and `system.nix` specifically to work around not having such a value.

The relevant fact this ADR turns into a mechanism:
- `home-manager.nixosModules.home-manager`, when Home Manager is evaluated _nested_ inside a `nixosSystem` call *(the case ADR-011 commits this repo to, for the `cypher-nixos` host),* passes the fully-evaluated NixOS configuration into the nested Home Manager module tree as the special argument `osConfig`.
- This is not available when Home Manager is evaluated standalone via `homeManagerConfiguration` — the shape ADR-011 also keeps, for iteration speed and for the non-NixOS lenses (Arch, Debian, Fedora, openSUSE) that have no NixOS graph to nest under at all.

## Decision

For any signal that must be a single source of truth across both evaluation contexts (currently: `cypher-os.profile.active`, `cypher-os.lens.current`):

1. The option is **declared and set exactly once**, in the NixOS-context option tree.
    
2. Home Manager modules, when nested (the `cypher-nixos` host), **read the value via `osConfig.cypher-os.<signal>`** rather than re-declaring or re-setting it.
    
3. Home Manager modules that also need to function under a **standalone** configuration *(non-NixOS lenses, or the standalone `cypher-nixos` HM entry point used for fast iteration)* fall back to a **locally declared and set value** when `osConfig` is unavailable, using the pattern:

```nix
{ config, osConfig ? null, lib, ... }:
let
  activeProfile =
    if osConfig != null
    then osConfig.cypher-os.profile.active
    else config.cypher-os.profile.active;
in
   { ... }
```
 
- On standalone lenses, the host's own `home.nix` must set `cypher-os.profile.active` *(and `cypher-os.lens.current`)* explicitly — this is the one unavoidable duplication point, accepted at the same tier as `home.username`/`home.homeDirectory` already being set per-host in `flake/home-configurations.nix`.


## Reasoning

This gives the `cypher-nixos` host — the primary, NixOS-integrated case — a genuine single source of truth:
- `profile.active` is authored in exactly one place, and every consumer, in either graph, resolves to that same value.
- It does not pretend the same is possible for standalone lenses, where no shared evaluation exists to read from.
- Those lenses accept explicit local duplication as the honest cost of not having a NixOS layer underneath them, rather than inventing an artificial mechanism *(e.g. a generated file read at eval time)* to paper over a boundary that's real.

The `osConfig ? null` fallback pattern generalizes past `profile.active` and `lens.current` — any future cross-context signal facing the same nested-vs-standalone split should use the identical shape, which is why this is recorded as its own ADR rather than folded into ADR-023 (a namespace-shape decision) or purely as an ADR-005 amendment (a file-layout convention) — it is a distinct, reusable mechanism about how a _value_, not just an _option declaration_, crosses the evaluation boundary.

## Alternatives Considered

### Manually keep both contexts' values in sync

The status quo before this ADR — exactly the pattern that produced the fonts `hm.nix`/`system.nix` duplication this session identified.

**Rejected:** it is not a mechanism, it is a discipline that has already been observed to fail once and will fail again as more categories need the same signal.

### A shared data file (plain Nix attrset, not a module) imported by both contexts

**Considered:**
- a file like `profiles/desktop.nix` returning a plain attrset, imported and interpreted identically by both graphs.

**Rejected:**
- in favor of `osConfig` for the NixOS-integrated case specifically, because a shared data file still requires the _value itself_ to be re-evaluated independently in each graph *(both graphs read the same file, but nothing guarantees a host override applied in one graph is reflected in the other's read of the same nominally-shared file)* — it solves "same authored source" but not "same resolved value," which was the actual gap.
- This approach remains the right one for the standalone-lens fallback case, where no `osConfig` exists to read at all.

## Consequences

**Positive:**

- `profile.active` and `lens.current` are genuine single sources of truth for the `cypher-nixos` host — *no possibility of the two graphs disagreeing about which profile or lens is active.*
  
- The fonts category's `hm.nix`/`system.nix` duplication is eliminated:
    - the HM-side file installs the full font set only when `lens.current != "nixos"`, with no manual list-keeping-in-sync required.
      
- The `osConfig ? null` pattern is documented once and reused for every future cross-context signal, rather than re-derived per category.

**Negative / Trade-offs:**

- Every module using this pattern must handle the `osConfig` absent case explicitly — *a module that assumes `osConfig` is always present will break under the standalone/non-NixOS lens configurations.*
  
- Standalone lenses still require explicit local duplication of `profile.active`/`lens.current` — this ADR does not eliminate that cost, only contains it to the smallest possible surface *(one or two lines per standalone host entry).*

**Neutral / Operational:**

- This mechanism depends on ADR-011's decision that Home Manager remains NixOS-module-integrated for the `cypher-nixos` host.
- If that decision were ever reversed, this ADR's nested-context path would need re-evaluating alongside it.