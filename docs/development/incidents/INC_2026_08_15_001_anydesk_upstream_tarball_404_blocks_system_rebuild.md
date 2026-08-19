# INC-2026-08-15-001: AnyDesk Upstream Tarball 404 Blocks System Rebuild

**ID:** INC_2026_08_15_001
**Date:** 2026-08-15
**Severity:** Medium
**Status:** Resolved
**Reported by:** CypherWhisperer

---

## Summary

`sudo nixos-rebuild --install-bootloader --flake .#cypher-nixos` failed because the `anydesk` derivation pinned by the flake's `nixpkgs` input fetches version 8.0.2's Linux tarball directly from `download.anydesk.com`, and that specific tarball has since been removed from AnyDesk's server following newer upstream releases *(8.0.3, 8.0.4).*

The failure cascaded through every derivation depending on `home-manager-path`, blocking the full system rebuild — n*ot just the AnyDesk package.*

---

## Timeline

| Time       | Event                                                                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-08-15 | `nixos-rebuild` invoked; build failed with `curl: (22) The requested URL returned error: 404`.                                                                                 |
| 2026-08-15 | Garnix cache 503 warnings noted alongside the failure; *initially suspected as a possible cause.*                                                                              |
| 2026-08-15 | Root cause isolated to the AnyDesk fixed-output derivation, not the Garnix warnings *(non-fatal.)*                                                                             |
| 2026-08-15 | Confirmed via AnyDesk's own Linux changelog that 8.0.2 was superseded by 8.0.3 *(Jun 23)* and 8.0.4 *(Jun 30, 2026.)*                                                          |
| 2026-08-15 | Overlay created *(`flake/overlays/anydesk.nix`)* pinning `anydesk` to 8.0.4 with a fresh hash and imported it from `flake/nixpkgs-config.nix`; *rebuild re-run and succeeded.* |

---

## Impact

- **Components affected:** `modules/apps/productivity/anydesk-hm.nix`; transitively, the entire `home-manager-generation` and `nixos-system-cypher-nixos` build graph.
- **Data affected:** None.
- **Time lost:** ~1 session *(investigation + fix authored same day.)*
- **Work affected:** CypherOS system rebuild blocked until resolved; *no other module work could land until the flake evaluated cleanly.*

---

## Root Cause

The `anydesk` package in the pinned `nixpkgs` revision is a fixed-output derivation that fetches its source tarball directly from `download.anydesk.com` at build time, rather than from a content-addressed mirror.

AnyDesk Software GmbH does not retain old Linux release tarballs indefinitely — each new release *(8.0.3, then 8.0.4)* appears to have resulted in the 8.0.2 tarball being pruned from their server.

Since the flake's `nixpkgs` input had not been updated since before this pruning, the derivation's hard-coded URL pointed at a resource that no longer existed.

This is a recurring, previously-documented failure mode for this specific package upstream in nixpkgs history *(version bumps repeatedly required after upstream tarball removal.)*

---

## Resolution

Added a local overlay overriding `anydesk` to fetch and build against the current upstream release (8.0.4) with a freshly prefetched hash, bypassing the stale, now-dead URL baked into the pinned nixpkgs revision's derivation.

### Changes Made

| Type    | Reference                                                                                              | Description                                                                  |
| ------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| File    | `flake/overlays/anydesk.nix`                                                                           | New overlay overriding `anydesk` src/version/hash to 8.0.4                   |
| File    | `flake/nixpkgs-config.nix`                                                                             | Imports the new overlay                                                      |
| ADR     | [ADR_015](../../project/decisions/ADR_015_2026_08_15_dropping_garnix_as_a_binary_cache_substituter.md) | Related decision made during the same session *(Garnix substituter removal)* |
| Journal | [2026_08_15](../journal/2026_08_15_anydesk_build_failure_and_garnix_removal.md)                        | Session notes                                                                |

---

## Contributing Factors

- Flake's `nixpkgs` input had not been updated recently enough to pick up nixpkgs' own upstream version bump for `anydesk`.
- No automated check exists to catch fixed-output-derivation URL rot before a full rebuild is attempted.
- AnyDesk's release cadence *(multiple point releases within weeks)* outpaces manual flake-lock update cadence.

---

## Prevention

- Adopt a regular `nix flake lock --update-input nixpkgs` cadence rather than updating reactively on build failure.
- Treat the overlay as temporary: 
    - re-check whether nixpkgs' own `anydesk` derivation has caught up on every `nixpkgs` bump, and drop the overlay once confirmed *(tracked as a journal reminder, see linked entry.)*
      
- Consider surfacing fixed-output-derivation packages *(anydesk, and similarly-fetched proprietary binaries)* as a known risk category worth periodic spot-checking.

---

## Lessons Learned

Fixed-output derivations that fetch directly from a vendor's own CDN are only as stable as the vendor's retention policy for old files — nixpkgs pinning a version does not guarantee that version stays fetchable.

The Garnix 503 noise in the same build output was a red herring for this particular incident; it's worth verifying which error in a multi-error build log is actually the blocking one before investigating, since retry-heavy warnings can look more alarming than the real `error:` line beneath them.

---

<!-- METADATA
Opened: 2026-08-15
Resolved: 2026-08-15
Related journal entry: [2026_08_15_anydesk_build_failure_and_garnix_removal](../journal/2026_08_15_anydesk_build_failure_and_garnix_removal.md)
-->