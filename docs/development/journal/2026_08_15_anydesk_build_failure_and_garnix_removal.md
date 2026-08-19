# [2026_08_15] AnyDesk Build Failure and Garnix Removal

**Date:** 2026-08-15
**Duration:** ~1 session
**Repos touched:** [ CypherOS ]
**Modules touched:**
1. `flake/overlays/anydesk.nix`
2. `flake/nixpkgs-config.nix`
3. `hosts/nixos/configuration.nix`
**Phase:**

---

## What I Worked On

`nixos-rebuild` for `cypher-nixos` was failing outright, with two different warning/error streams in the output at once:
- repeated `cache.garnix.io` 503s, and a hard `error:` from a failed AnyDesk build *(`curl: (22) The requested URL returned error: 404`).*
- Needed to separate which of the two was actually blocking the rebuild, fix that, and figure out what to do about the other.

---

## What Got Done

- Diagnosed the actual blocker:
    - the `anydesk` derivation in the pinned `nixpkgs` revision fetches 8.0.2's tarball directly from `download.anydesk.com`, and that specific file no longer exists upstream *(superseded by 8.0.3, then 8.0.4.)*
      
- Confirmed the Garnix 503s were unrelated noise, not the cause of the failed build,
- Created `flake/overlays/anydesk.nix` overriding `anydesk` to build against 8.0.4, using `nix-prefetch-url` + hash format conversion for the new source hash.
- Imported the overlay from `flake/nixpkgs-config.nix`; rebuild succeeded.
- Filed [INC_2026_08_15_001](../incidents/INC_2026_08_15_001_anydesk_upstream_tarball_404_blocks_system_rebuild.md) for the build failure.
- Investigated the Garnix 503s separately and confirmed they're not a local config/credentials issue:
    - Garnix's hosted service *(cache + CI)* shut down July 15th, 2026 as part of joining Shopify; codebase open-sourced at [garnix-io/garnix-ci](https://github.com/garnix-io/garnix-ci)
- Filed [ADR_015](../../project/decisions/ADR_015_2026_08_15_dropping_garnix_as_a_binary_cache_substituter.md) deciding to drop `cache.garnix.io` from `substituters`/`trusted-public-keys`.

---

## Key Decisions Made

Captured in [ADR_015](../../project/decisions/ADR_015_2026_08_15_dropping_garnix_as_a_binary_cache_substituter.md) — dropping Garnix as a substituter rather than self-hosting or switching to a CI alternative right now; both deferred as out of scope for a single-user, single-machine flake at this stage.

---

## Where I Got Stuck

Initially the Garnix 503 noise made the build log look worse than it was — easy to assume a cache outage was the root cause when the real blocker was a completely separate fixed-output-derivation 404 further down the log.

---

## What I Learned

Fixed-output derivations that pull straight from a vendor's own CDN *(AnyDesk's `download.anydesk.com`)* are only as durable as that vendor's file retention — *`nixpkgs` pinning a version number doesn't guarantee the underlying tarball URL stays alive.*

The overlay fix is a bridge, not a permanent solution:
- `nixpkgs`' own maintainers/bots routinely bump packages like this after upstream releases, so the durable fix is keeping the `nixpkgs` flake input current, not maintaining a hand-rolled version/hash pin indefinitely.

---

## Open Questions

- How current is the pinned `nixpkgs` input generally — *is a broader update overdue beyond just what's needed for AnyDesk?*
- Once `nixpkgs` is updated, does its own `anydesk` derivation resolve cleanly without the overlay?

---

## Next Session

- [ ] Bump the `nixpkgs` flake input *(`nix flake lock --update-input nixpkgs`)*
- [ ] Verify AnyDesk support against the updated `nixpkgs` revision *(does `pkgs.anydesk` build/resolve without the overlay?)*
- [ ] If confirmed working, drop `flake/overlays/anydesk.nix` and its import from `flake/nixpkgs-config.nix`

---

<!-- Commit range:
CypherOS: [short hash] → [short hash]
-->