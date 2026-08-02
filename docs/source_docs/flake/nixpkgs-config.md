<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Overlays / nixpkgs.config SSOT — _`nixpkgs-config.nix`_

> _Declares the flake's overlay list and `nixpkgs.config` exactly once, as a function of `inputs`, for both evaluation paths to consume._

**Module path:** `flake/nixpkgs-config.nix`
**Evaluation context:** Both;
- plain Nix data, evaluated once by `flake/default.nix`
- its output feeds both the NixOS system's `nixpkgs.overlays`/`nixpkgs.config` and the standalone `homeConfigurations`' `pkgs` instantiation
**Status:** Stable
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Declares the complete overlay list *(`nix-vscode-extensions`, `nur`, `claude-desktop`)* as a single value
- Declares `nixpkgs.config` *(`allowUnfree`, `permittedInsecurePackages`)* as a single value
- Exposes both as one attribute set, `{ overlays; config; }`, for any consumer to import

**Does not:**

- Instantiate `pkgs` itself — that's `flake/default.nix`'s job, using this file's output
- Wire the values into `nixosConfigurations` or `homeConfigurations` — *that's `flake/hosts.nix` and `flake/home-configurations.nix` respectively*
- Declare any `cypher-os.*` options — *this file is flake-level plumbing, outside the `modules/` option namespace entirely*

---

## Evaluation Context

| Property              | Value                                                                                                                                                                                                                         |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Evaluated by          | Neither `nixosModules` nor `homeManagerModules` directly — a plain function called once from `flake/default.nix` at flake-evaluation time; its _output_ is what both module systems ultimately consume                        |
| Options namespace     | None — this file declares plain data *(an overlay list and a config attrset),* not `cypher-os.*` options                                                                                                                      |
| Imports `options.nix` | No — not part of the `modules/` option-declaration tree                                                                                                                                                                       |
| Kill-switch guard     | None — unconditional; every host and every HM evaluation gets the same overlays/config by design (see [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)) |
| Profile default       | Not applicable                                                                                                                                                                                                                |

---

## Block Analysis

### Block 1 — Function signature

**What is this?** A function taking one argument, `{ inputs }`, and returning an attribute set.

**What does it do?** Nothing on its own — it's a pure function. When called (from `flake/default.nix` as `import ./nixpkgs-config.nix { inherit inputs; }`), it evaluates to the `{ overlays; config; }` attrset below.

**Why is it here?** Taking `inputs` as an argument (rather than being a flake input itself, or hardcoding flake references) is what lets this file be a plain, portable Nix value — it has no dependency on being imported from any particular evaluation context, which is exactly what lets both `flake/hosts.nix` (NixOS-module context) and `flake/home-configurations.nix` (standalone HM context) consume it identically.

```nix
{ inputs }:
```

---

### Block 2 — `overlays`

**What is this?** A list of three overlay functions, each pulled from a flake input's `overlays.default` output.

**What does it do?** When passed into `import nixpkgs { overlays = ...; }` (standalone path) or the NixOS module's `nixpkgs.overlays` option (system path), each overlay is applied in list order to the resulting `pkgs`, layering in `pkgs.nix-vscode-extensions.*`, NUR's package set, and `pkgs.claude-desktop`.

**Why is it here?** This is the exact list that previously existed in triplicate — once in `flake.nix`'s top-level `let pkgs`, once inline in `nixosConfigurations.cypher-nixos`'s `modules`, and once (missing `nur`) in `hosts/nixos/configuration.nix` — and had already drifted out of sync across those copies, causing the `claude-desktop` "attribute missing" bug in [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md). Consolidating to one list, consumed by reference rather than copied, is the direct fix — see [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) for the full reasoning and rejected alternatives.

```nix
overlays = [
  inputs.nix-vscode-extensions.overlays.default
  inputs.nur.overlays.default
  inputs.claude-desktop.overlays.default
];
```

---

### Block 3 — `config`

**What is this?** An attribute set matching the shape of Nixpkgs' `nixpkgs.config` — `allowUnfree` and `permittedInsecurePackages`.

**What does it do?** `allowUnfree = true` permits evaluation of unfree-licensed packages (needed for `claude-desktop`, among others) instead of erroring at eval time. `permittedInsecurePackages` allowlists two specific packages (`electron-39.8.10`, `ventoy-1.1.12`) that Nixpkgs would otherwise refuse to build due to known advisories, on the basis that their use here is accepted/understood.

**Why is it here?** Same rationale as Block 2 — this was previously duplicated between the flake-level overlay block and `hosts/nixos/configuration.nix`, and the `electron-39.8.10` entry specifically exists because of Logseq's Electron dependency (per prior CypherOS work). Bundling `config` alongside `overlays` in one return value, rather than as a second separate SSOT file, was a deliberate choice — the two are both "how this flake's `pkgs` is built" concerns and change together often enough that splitting them into two files would mean two imports at every call site for no isolation benefit.

```nix
config = {
  allowUnfree = true;
  permittedInsecurePackages = [
    "electron-39.8.10"
    "ventoy-1.1.12"
  ];
};
```

---

## Dependencies

**Imported files:**

- None — this file has no `imports`; it's a leaf in the dependency graph, only ever consumed, never itself importing anything else in the repo

**NixOS options set by this file:** _(not applicable — this file doesn't set options directly; its output is later assigned to `nixpkgs.overlays`/`nixpkgs.config` by `flake/hosts.nix`)_

**Home Manager options set by this file:** _(not applicable — same reasoning; consumed by `flake/default.nix` to build the `pkgs` passed into `flake/home-configurations.nix`)_

**nixpkgs packages required:** None directly — the overlays reference packages, but this file itself only references flake inputs' `overlays.default` attributes

**External flake inputs used:**

- `inputs.nix-vscode-extensions`
- `inputs.nur`
- `inputs.claude-desktop`

---

## Option Surface

Not applicable — this file declares no `cypher-os.*` options and reads none. It is flake-level configuration plumbing, entirely outside the `modules/` option namespace.

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

_Not currently used in this file — there is no deferred/excluded/pending package list here, only the two active lists in Blocks 2–3. Retained as a standing convention for when one is added._

---

## Design Notes

1. Returning `{ overlays; config; }` as one attrset rather than two separate files *(`overlays.nix` + `nixpkgs-config.nix`)* was chosen because both are consumed together at every call site *(`flake/hosts.nix` and `flake/home-configurations.nix` both need both values)* — splitting them would add import overhead with no corresponding isolation win.
   
2. Taking `{ inputs }` rather than being structured as its own tiny flake was deliberate: it stays a plain, dependency-free Nix value, importable from anywhere in the repo without needing its own `inputs`/`outputs` boilerplate.
   
3. No per-host override mechanism exists yet *(see [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md), Negative/Trade-offs)* — if a second host ever needs a different overlay or config subset, this file's function signature will need to grow *(e.g. accepting a host-name argument)* rather than remaining a flat, unconditional value.
   

_See [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) for the full decision record._

---

## Known Limitations

1. No mechanism for a host or HM context to opt out of, or extend, an individual overlay without editing this file directly — *acceptable while `cypher-nixos` is the only host, revisit once a second host with different needs exists*
  
2. `permittedInsecurePackages` entries *(`electron-39.8.10`, `ventoy-1.1.12`)* are not documented here with the reason each was added — that context currently lives only in prior CypherOS work/journal entries, not inline; _a logseq setup for the former and simply an installation need for the latter_

---

## Related

| Type                   | Reference                                                                                                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Options declared in    | Not applicable — no `options.nix` counterpart                                                                                                                                                                       |
| Counterpart file       | None — this is a standalone SSOT, not part of an `hm.nix`/`system.nix` pair                                                                                                                                         |
| Profile default set in | Not applicable                                                                                                                                                                                                      |
| ADR                    | [ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)                                           |
| Incident               | [INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) |

---

<!-- METADATA 
Module: flake/nixpkgs-config.nix 
Context: Both (NixOS system + Home Manager, via flake/default.nix) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->