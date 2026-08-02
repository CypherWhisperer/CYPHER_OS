<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# DevShells — `devshells.nix`

> _Scaffolded home for `devShells.<system>` (`nix develop` environments); currently an empty stub._

**Module path:** `flake/devshells.nix` 
**Evaluation context:** Both:
- a flake output, callable from either NixOS or non-NixOS environments — *devshells are independent of `nixosConfigurations`/`homeConfigurations`*
**Status:** Planned 
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Provides the designated location for `devShells.${system}` definitions, wired into `flake/default.nix`'s output assembly
- Receives `inputs`, `system`, and the shared `pkgs` *(same instance `flake/home-configurations.nix` receives)* as arguments, ready for use once populated

**Does not:**

- Currently define any devshells — *the file returns an empty attrset*
- Duplicate or reference `nixamp` or any other existing devenv setup — *those remain wherever they currently live until explicitly migrated here (not yet decided)*

---

## Evaluation Context

| Property              | Value                                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Evaluated by          | Neither `nixosModules` nor `homeManagerModules` — _a plain flake-output function, evaluated on demand by `nix develop`_ |
| Options namespace     | None                                                                                                                    |
| Imports `options.nix` | No                                                                                                                      |
| Kill-switch guard     | Not applicable                                                                                                          |
| Profile default       | Not applicable                                                                                                          |

---

## Block Analysis

### Block 1 — Function signature and empty return

**What is this?** A function of `{ inputs, system, pkgs }` returning `{}`.

**What does it do?** Nothing yet — `devShells.${system}` currently resolves to an empty attrset, meaning `nix develop` has no default shell defined via this mechanism.

**Why is it here?** Created as part of the [`flake.nix` modularization](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) specifically so devshell work has an obvious, already-wired destination the moment it's needed, rather than being added to `flake/default.nix` directly or left undecided. The three arguments (`inputs`, `system`, `pkgs`) were chosen to match what a typical devshell definition needs — access to flake inputs (e.g. `devenv.lib.mkShell`), the target system, and the SSOT-consistent `pkgs` — without yet committing to what will actually be built with them.

```nix
{ inputs, system, pkgs }:
{
}
```

---

## Dependencies

**Imported files:** None currently

**NixOS options set by this file:** Not applicable

**Home Manager options set by this file:** Not applicable

**nixpkgs packages required:** None currently — `pkgs` is received but unused

**External flake inputs used:** None currently — `inputs.devenv` is available in the flake's `inputs` but not yet referenced here

---

## Option Surface

Not applicable.

---

## Comment Convention

Inline comments in source files use three header tiers to classify non-active code without explanation bloat. Deep rationale belongs here in the documentation, not in the source file.

```nix
# ── DEFERRED — not yet needed; low friction to add ───────────────────────────
# package-name  # reason: <one line>

# ── EXCLUDED — active decision not to include ────────────────────────────────
# package-name  # reason: BSL license / broken nixpkgs derivation / etc.

# ── PENDING — blocked on something external ──────────────────────────────────
# package-name  # blocked on: <what>
```

_Not currently used — the file's entire content is itself DEFERRED, in effect; no individual lines are annotated._

---

## Design Notes

- Deliberately left empty rather than populated with a guessed-at default shell — this file was scaffolded during the flake modularization pass specifically to have a destination ready, not to make a decision about devshell content that wasn't part of that pass's scope.
  
- Whether `nixamp` and other existing devenv work eventually move here, or remain independent, is an open question — see the parent journal entry's "Open Questions" section.

---

## Known Limitations

- Provides no devshells today — any existing `nix develop` workflow (e.g. for `nixamp`) is unaffected by this file until/unless explicitly migrated into it
  
- No `inputs.devenv` usage yet, despite `devenv` being a pinned flake input — if devshell work does land here, `devenv.lib.mkShell` vs. plain `pkgs.mkShell` is an open choice, not yet made

---

## Related

| Type                   | Reference                                                                                                                      |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Options declared in    | Not applicable                                                                                                                 |
| Counterpart file       | None — no `system.nix`/`hm.nix` split applies to devshells                                                                     |
| Profile default set in | Not applicable                                                                                                                 |
| ADR                    | [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) |
| Incident               | None                                                                                                                           |

---

<!-- METADATA 
Module: flake/devshells.nix 
Context: Both (flake output, environment-independent) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->