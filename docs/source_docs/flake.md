<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Flake Entry Point — `flake.nix`

> _Declares every external input this configuration depends on, then delegates all output construction to `flake/`._

**Module path:** `flake.nix` 
**Evaluation context:** Both:
- the root of every evaluation — *NixOS, standalone Home Manager, and `nix flake check` all start here*
**Status:** Stable 
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Declares `description` and the full `inputs` set — every external flake this configuration depends on, with `inputs.nixpkgs.follows = "nixpkgs"` set on each to deduplicate against the one pinned `nixpkgs` revision
  
- Destructures the resolved inputs in `outputs` and delegates immediately to `flake/default.nix`

**Does not:**

- Contain any `let`, `system`, `pkgs`, or output-construction logic — all of that moved to `flake/` as of [ADR_013_2026_07_31](../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md)
  
- Pin package versions or overlays directly — inputs here are only _which flakes_, not _how they're combined_, which is `flake/nixpkgs-config.nix`'s responsibility

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|The Nix flake evaluator itself — this is the file every `nix`/`nixos-rebuild`/`home-manager` invocation with `--flake` starts from|
|Options namespace|None — no `nixpkgs.*`/`home-manager.*`/`cypher-os.*` options are set here|
|Imports `options.nix`|No, not directly|
|Kill-switch guard|Not applicable|
|Profile default|Not applicable|

---

## Block Analysis

### Block 1 — `description`

**What is this?** `description = "CypherOS unified multi-OS configuration flake";` — the flake's required top-level metadata field.

**What does it do?** Surfaces in `nix flake show`/`nix flake metadata` output; otherwise inert.

**Why is it here?** Required by the flake schema; the wording ("unified multi-OS") reflects the long-term shared-home multi-lens architecture goal, not just the currently-single `cypher-nixos` host.

```nix
description = "CypherOS unified multi-OS configuration flake";
```

---

### Block 2 — `nixpkgs` input

**What is this?** `nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";`, with a commented-out stable-channel alternative and inline notes on pinning to a specific Hydra-tested commit.

**What does it do?** Selects the Nixpkgs revision every other input's `follows` points back at, and what `flake/nixpkgs-config.nix`'s `pkgs` is ultimately built from.

**Why is it here?** Unstable was chosen for rolling package availability. The commented stable alternative and the Hydra-commit-pinning notes are retained as an operational runbook-in-comment-form for when reproducibility across time matters more than package freshness — not currently acted on, but deliberately not deleted.

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
```

---

### Block 3 — `home-manager` input

**What is this?** `home-manager.url = "github:nix-community/home-manager/master"; home-manager.inputs.nixpkgs.follows = "nixpkgs";` — with commented stable-release alternatives.

**What does it do?** Pins Home Manager to its `master` branch (tracking `nixpkgs-unstable`, consistent with Block 2), and `follows` ensures HM evaluates against the exact same Nixpkgs revision as everything else rather than fetching and evaluating a second, independent copy.

**Why is it here?** `follows` here is the same deduplication mechanism used on every other input in this file — declared once per input rather than assumed, since Nix does not apply it automatically. This is directly relevant to why `flake/nixpkgs-config.nix`'s SSOT fix works at all: if HM's own `nixpkgs` didn't follow the flake's, unifying overlays at the `flake/` level wouldn't have been sufficient — HM would still be evaluating a different Nixpkgs tree underneath.

```nix
home-manager = {
  url = "github:nix-community/home-manager/master";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

---

### Block 4 — Overlay-contributing and HM-module-contributing inputs

**What is this?** Five inputs sharing an identical shape: `claude-desktop`, `nix-vscode-extensions`, `catppuccin`, `devenv`, `nur` — each a `url` plus `inputs.nixpkgs.follows = "nixpkgs"`.

**What does it do?** `claude-desktop`, `nix-vscode-extensions`, and `nur` each contribute an `overlays.default`, consumed by `flake/nixpkgs-config.nix` (Block 2 of that file). `catppuccin` contributes `homeModules.catppuccin`, consumed separately by both `flake/hosts.nix` and `flake/home-configurations.nix` (per the re-import pattern documented in the latter). `devenv` is pinned but not yet consumed anywhere — see `flake/devshells.nix`.

**Why is it here?** Grouped as one block in this documentation (though declared as five separate input entries in the source) because they share both their structural shape and their purpose: every one of them exists specifically to be deduplicated against the pinned `nixpkgs` and then flow into exactly one of the two consumption paths described in `flake/nixpkgs-config.nix` (overlays) or the HM-module-import pattern (`catppuccin`). Adding a sixth input of either kind follows this exact template.

```nix
claude-desktop = {
  url = "github:aaddrick/claude-desktop-debian";
  inputs.nixpkgs.follows = "nixpkgs";
};
nix-vscode-extensions = {
  url = "github:nix-community/nix-vscode-extensions";
  inputs.nixpkgs.follows = "nixpkgs";
};
catppuccin = {
  url = "github:catppuccin/nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
devenv = {
  url = "github:cachix/devenv";
  inputs.nixpkgs.follows = "nixpkgs";
};
nur = {
  url = "github:nix-community/NUR";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

---

### Block 5 — `outputs` delegation

**What is this?** `outputs = { self, nixpkgs, home-manager, claude-desktop, nix-vscode-extensions, catppuccin, devenv, nur, ... }@inputs: import ./flake { inherit inputs; };`

**What does it do?** Destructures every declared input by name (required so each is available individually if ever needed at this level, and so the `@inputs` binding captures the full set), then immediately hands the whole `inputs` attrset to `flake/default.nix` and returns whatever it produces as this flake's outputs.

**Why is it here?** This single line is the entire point of [ADR_013_2026_07_31](../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) — everything that used to follow this line inline (the `let system = ...`, the `pkgs` instantiation, both `nixosConfigurations` and `homeConfigurations` in full) now lives in `flake/`. The `@inputs` capture pattern (rather than just `inputs: import ./flake { inherit inputs; };` without named destructuring) is retained from the pre-refactor file specifically so that adding a new input to the block above requires no corresponding change here — `@inputs` already captures it.

```nix
outputs =
  {
    self,
    nixpkgs,
    home-manager,
    claude-desktop,
    nix-vscode-extensions,
    catppuccin,
    devenv,
    nur,
    ...
  }@inputs:
  import ./flake { inherit inputs; };
```

---

## Dependencies

**Imported files:**

- `./flake` (resolves to `./flake/default.nix`) — the entire output-construction delegation

**NixOS options set by this file:** None

**Home Manager options set by this file:** None

**nixpkgs packages required:** None directly

**External flake inputs used:** All of them — this file is where every one is declared

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

_The commented stable-channel alternatives in Blocks 2–3 predate this three-tier convention but function as DEFERRED-tier entries — ready-to-use alternatives, not currently active._

---

## Design Notes

- Keeping `inputs` in `flake.nix` (rather than also moving it into `flake/`) was not a point of debate during the modularization — the flake schema requires `inputs` and `outputs` to be declared in the file literally named `flake.nix`; there was never a choice here, only in how much of `outputs` stays inline.
  
- The extensive inline comments on Nixpkgs commit-pinning (Block 2) predate this documentation file and are retained deliberately — they encode operational knowledge (how to find a Hydra-tested commit) that doesn't fit neatly into an ADR or this module-doc format, so the source comment remains the right home for it.

_See [ADR_013_2026_07_31](../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) for the full decision record._

---

## Known Limitations

- No automated check that every input declared here is actually consumed somewhere in `flake/` — `devenv` is a live example of a currently-unconsumed input, which is intentional but not enforced
  
- `follows = "nixpkgs"` is repeated per-input rather than expressed once — this is a Nix flake-schema constraint, not a design choice available to change here

---

## Related

| Type                   | Reference                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Options declared in    | Not applicable                                                                                                                             |
| Counterpart file       | `flake/default.nix` (everything this file delegates to)                                                                                    |
| Profile default set in | Not applicable                                                                                                                             |
| ADR                    | [ADR_013_2026_07_31](../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md)                |
| Incident               | [INC_2026_07_27_001](../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) |

---

<!-- METADATA 
Module: flake.nix Context: 
Both (root entry point) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->