# ADR_015_2026_08_15: Dropping Garnix as a Binary Cache Substituter

**Date:** 2026-08-15
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

`hosts/nixos/configuration.nix` listed `https://cache.garnix.io` among the flake's `substituters`, alongside its `trusted-public-keys` entry.

During a routine `nixos-rebuild`, every substituter lookup against Garnix returned repeated `HTTP error 503` responses *(`No server is available to handle this request`),* retried five times per lookup before Nix fell through to other substituters or built locally.

This didn't block the rebuild itself — the actual blocker that day was an unrelated AnyDesk tarball 404 *(see [INC_2026_08_15_001](../../development/incidents/INC_2026_08_15_001_anydesk_upstream_tarball_404_blocks_system_rebuild.md))* — but the 503s persisted across multiple rebuilds afterward, with no local config changes to `configuration.nix`'s substituter block, and no similar issue on the other three configured substituters *(`cache.nixos.org`, `nix-community.cachix.org`, `nixpkgs-terraform.cachix.org`).*

Investigation confirmed this isn't a transient outage or a credentials/config issue on the CypherOS side:
- Garnix announced in May 2026 that it was joining Shopify, and as part of that transition the hosted `garnix.io` service — *including its binary cache* — was shut down on July 15th, 2026.
- The codebase was open-sourced for anyone wanting to self-host an instance. 
- `cache.garnix.io` returning 503 is therefore expected, permanent behavior from a service that no longer exists in hosted form, not a fixable fault.

---

## Decision

Remove `https://cache.garnix.io` from `substituters` and its corresponding entry from `trusted-public-keys` in `hosts/nixos/configuration.nix`.

---

## Reasoning

There is nothing to fix or reconnect to — *the hosted Garnix cache is permanently offline.*

Keeping a dead substituter in the list costs five retries' worth of latency *(with exponential backoff)* on every single rebuild, for a cache that will never respond.

Removing it is a pure win:
- no packages CypherOS relies on were Garnix-cache-exclusive *(they resolve fine from `cache.nixos.org` / `nix-community.cachix.org`, just without whatever speed-up Garnix previously offered for community-CI-built derivations),* and the other three substituters are confirmed healthy and untouched by this change.

---

## Alternatives Considered

### Self-host a Garnix instance

Garnix open-sourced its CI/cache codebase specifically to let existing users migrate to self-hosted or shared instances.

**Rejected for now:**
- This is infrastructure overhead *(hosting, maintenance, storage for a binary cache)* disproportionate to what Garnix was providing CypherOS — *a modest speed-up on a single-user, single-machine flake.*
- Worth revisiting if CypherOS's `cypher-server` VPS host profile matures to the point where self-hosting a shared cache for multiple lenses/hosts becomes worthwhile.

### Migrate to nix-ci.com *(community-suggested Garnix alternative)*

Surfaced in community discussion as a direct successor for former Garnix users. 

**Rejected for now:** 
- This ADR concerns the binary-cache substituter, not a CI product — *CypherOS doesn't currently run Nix CI against a remote service.*
- Worth evaluating separately if/when repos need CI, but out of scope here.

### Leave the entry in place, ignore the warnings

**Rejected:**
- 503 retries add measurable latency to every rebuild indefinitely, for a service confirmed never to return.
- No upside to leaving it configured.

---

## Consequences

**Positive:**

- Rebuilds no longer spend time retrying a dead substituter *(5 attempts with backoff, every build.)*
- `configuration.nix`'s substituter list now accurately reflects reality — *reduces confusion for future-me reading it.*
- Cleaner rebuild output, easier to spot genuine errors *(this ADR exists partly because Garnix noise made the real AnyDesk 404 harder to eyeball at first glance.)*

**Negative / Trade-offs:**

- Lose whatever cache hit rate Garnix was providing for community-CI-built derivations not otherwise cached by `cache.nixos.org` or `nix-community.cachix.org` — *likely means marginally more local builds for niche packages going forward.*
  
- No current self-hosted or third-party replacement configured; that gap is accepted, not solved, by this decision.

**Neutral / Operational:**

- One-line removal in `hosts/nixos/configuration.nix` *(both `substituters` and `trusted-public-keys` entries.)*
- Garnix's codebase remains available at [github.com/garnix-io/garnix-ci](https://github.com/garnix-io/garnix-ci) if self-hosting is revisited later

---

<!-- NOTES:
Confirmed via NixOS Discourse announcement thread + Garnix's own GitHub org (garnix-io/garnix-ci) as of 2026-08-15. Re-check garnix-io/issues if self-hosting is picked up later, for known migration pain points.
-->