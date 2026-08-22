# Runbook: Adding a New Overlay

**Last verified:** 2026-08-22
**Host:** `cypher-nixos`
**Module:** `flake/overlays/`, `flake/nixpkgs-config.nix`
**Trigger:** Reactive
**Estimated time:** ~10 minutes

---

## When To Use This Runbook

You need to override or patch a package from an upstream source *(a fork, a version pin, a local patch)*

## Prerequisites

- Confirm the change genuinely needs an overlay rather than an `overrideAttrs` at the point of use — an overlay is for something that should apply everywhere the package is referenced, not a one-off tweak.

## Procedure

### Step 1 — Create the overlay file

```bash
touch flake/overlays/<name>.nix
```

```nix
final: prev: {
  <package-name> = prev.<package-name>.overrideAttrs (old: {
    # ...
  });
}
```

Expected output: file created, following the same shape as `flake/overlays/anydesk.nix`.

### Step 2 — Register it in `nixpkgs-config.nix`

Add `(import ./overlays/<name>.nix)` to the `overlays` list in `flake/nixpkgs-config.nix` — this is the single source of truth both the NixOS and Home Manager `pkgs` instances draw from (per [ADR_012](../decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)).

If this step fails: check that the overlay list is a plain Nix list.
### Step 3 — Verify

```bash
nix flake check
nixos-rebuild build --flake .#cypher-nixos
```

Expected result: the overridden package builds; `nix eval .#nixosConfigurations.cypher-nixos.pkgs.<package-name>.version` reflects the change if it's a version bump.

---

## Troubleshooting

### The override doesn't seem to apply anywhere

Confirm the overlay is actually registered in `nixpkgs-config.nix` — a file existing in `flake/overlays/` does nothing on its own until it's in the `overlays` list.

## Rollback

Remove the overlay's entry from `nixpkgs-config.nix`, then delete the overlay file.

## Related

- ADR: [ADR_012](../decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)

---

<!--
METADATA
Created: 2026-08-22
Updated: 2026-08-22
Tested by: Cypher Whisperer
-->