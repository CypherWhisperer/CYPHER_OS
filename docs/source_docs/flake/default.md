<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Flake Composition Point — `default.nix`

> _Builds the shared `pkgs` from the SSOT overlays/config, then composes `hosts.nix`, `home-configurations.nix`, and `devshells.nix` into the final flake outputs attrset._

**Module path:** `flake/default.nix`
**Evaluation context:** Both:
- the single point where NixOS-context and Home-Manager-context outputs are assembled, though this file itself is plain flake-evaluation-time Nix
**Status:** Stable
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Fixes `system = "x86_64-linux"` once, for the whole flake
- Calls `flake/nixpkgs-config.nix` to obtain the SSOT `{ overlays; config; }`
- Instantiates the shared `pkgs` used by `flake/home-configurations.nix` (and implicitly, by extension, whatever else in `flake/` needs a plain `pkgs`)
- Calls `flake/hosts.nix`, `flake/home-configurations.nix`, and `flake/devshells.nix`, assembling their results into `nixosConfigurations`, `homeConfigurations`, and `devShells.${system}`

**Does not:**

- Declare any host, HM, or devshell content directly — every actual definition lives in the file it delegates to
- Declare overlays/config values — imports them from `flake/nixpkgs-config.nix`

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|Neither `nixosModules` nor `homeManagerModules` directly — plain Nix, evaluated once per `nix` invocation as the entry point `flake.nix` delegates to|
|Options namespace|None — this file sets no `cypher-os.*`, `nixpkgs.*`, or `home-manager.*` options itself; it only passes values through to the files that do|
|Imports `options.nix`|No, not directly — happens transitively once `hosts.nix`/`home-configurations.nix` pull in `modules/home/default.nix`|
|Kill-switch guard|Not applicable|
|Profile default|Not applicable|

---

## Block Analysis

### Block 1 — Function signature

**What is this?** A function of `{ inputs }`, matching what `flake.nix` calls it with (`import ./flake { inherit inputs; }`).

**What does it do?** Establishes the single entry point into everything under `flake/`.

**Why is it here?** `flake.nix` itself deliberately carries no logic beyond the `inputs` block and this one call — see [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md). This function signature is what makes that possible: everything `flake.nix` used to do inline now happens here instead.

```nix
{ inputs }:
```

---

### Block 2 — `system`

**What is this?** `system = "x86_64-linux";`, a `let`-bound value.

**What does it do?** Fixes the CPU/OS pair used everywhere a `system`-scoped value is needed in this flake: `nixosSystem`'s `system` argument, `import nixpkgs { system; }`, and `devShells.${system}`.

**Why is it here?** Declared once here rather than repeated at each of the three call sites it used to appear at pre-refactor (top-level `let`, inside `nixosConfigurations`, and implicitly wherever `devShells` would have needed it). A single-architecture flake doesn't strictly need this centralized, but it's the natural seam for eventually supporting more than one `system` (e.g. `aarch64-linux`) without hunting down every hardcoded occurrence.

```nix
system = "x86_64-linux";
```

---

### Block 3 — SSOT resolution and shared `pkgs`

**What is this?** `nixpkgsCfg = import ./nixpkgs-config.nix { inherit inputs; };` followed by `pkgs = import inputs.nixpkgs { inherit system; overlays = nixpkgsCfg.overlays; config = nixpkgsCfg.config; };`.

**What does it do?** Calls the SSOT file once, then builds exactly one `pkgs` value from its output — this is the `pkgs` handed to `flake/home-configurations.nix`.

**Why is it here?** This is the literal implementation of [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md): calling `nixpkgs-config.nix` exactly once, in exactly one place, and deriving the standalone-HM `pkgs` from that single call, is what guarantees `flake/hosts.nix` and `flake/home-configurations.nix` can never see divergent overlay lists again — they're both fed from this one evaluation, not from two independent `import nixpkgs { ... }` calls.

```nix
nixpkgsCfg = import ./nixpkgs-config.nix { inherit inputs; };
pkgs = import inputs.nixpkgs {
  inherit system;
  overlays = nixpkgsCfg.overlays;
  config = nixpkgsCfg.config;
};
```

---

### Block 4 — Output assembly

**What is this?** The final returned attrset: `nixosConfigurations`, `homeConfigurations`, and `devShells.${system}`, each assigned the result of importing and calling the corresponding `flake/*.nix` file.

**What does it do?** `nixosConfigurations` receives `nixpkgsOverlays`/`nixpkgsConfig` directly from `nixpkgsCfg` (not from `pkgs`) — `flake/hosts.nix` builds its own `pkgs` internally via NixOS's own `nixpkgs.overlays`/`nixpkgs.config` module options, so it needs the raw overlay/config values, not an already-instantiated `pkgs`. `homeConfigurations` and `devShells.${system}` both receive the already-built `pkgs` from Block 3, since neither needs to construct its own.

**Why is it here?** This asymmetry — `hosts.nix` getting raw overlay/config values while `home-configurations.nix` gets a finished `pkgs` — reflects a real, non-arbitrary difference between how NixOS and standalone HM each want to receive Nixpkgs configuration, and is worth understanding rather than "fixing" toward false symmetry: NixOS's module system constructs its own `pkgs` internally from `nixpkgs.overlays`/`nixpkgs.config` regardless of what's handed to it, so passing it a pre-built `pkgs` would do nothing useful there.

```nix
{
  nixosConfigurations = import ./hosts.nix {
    inherit inputs system;
    nixpkgsOverlays = nixpkgsCfg.overlays;
    nixpkgsConfig = nixpkgsCfg.config;
  };

  homeConfigurations = import ./home-configurations.nix {
    inherit inputs pkgs;
  };

  devShells.${system} = import ./devshells.nix {
    inherit inputs system pkgs;
  };
}
```

---

## Dependencies

**Imported files:**

- `./nixpkgs-config.nix` — SSOT overlays/config
- `./hosts.nix` — `nixosConfigurations`
- `./home-configurations.nix` — `homeConfigurations`
- `./devshells.nix` — `devShells.${system}`

**NixOS options set by this file:** None directly — passes values through to `hosts.nix`, which sets them

**Home Manager options set by this file:** None directly — passes `pkgs` through to `home-configurations.nix`

**nixpkgs packages required:** None directly

**External flake inputs used:**

- `inputs.nixpkgs` (both `.lib.nixosSystem`, used inside `hosts.nix`, and the direct `import inputs.nixpkgs { ... }` call in Block 3)

---

## Option Surface

Not applicable — this file declares no `cypher-os.*` options and reads none.

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

_Not currently used in this file — no deferred/excluded/pending content here._

---

## Design Notes

- The `hosts.nix`/`home-configurations.nix` argument asymmetry (Block 4) is the one part of this file most likely to look like an inconsistency to a future reader — documented explicitly above specifically so it isn't "fixed" into false symmetry later.
  
- `system` is currently a flat string rather than a list, matching the single-host reality of CypherOS today. Multi-`system` support (were `aarch64-linux` ever needed) would mean this file growing a `forEachSystem`-style helper rather than a structural change — this is exactly the kind of need `flake-parts`' `perSystem` scope exists for, and was cited as a deferred-adoption trigger in [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md).

_See [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) and [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) for the full decision records._

---

## Known Limitations

- Single-`system` only — every consumer of this file assumes `x86_64-linux`; extending to a second architecture would require touching this file's structure, not just adding a host
  
- No validation that `hosts.nix`/`home-configurations.nix`/`devshells.nix` return well-formed attrsets — a malformed return from any of them surfaces as a `nix flake check` or build-time error traced back through this file rather than a clear error at the source file itself

---

## Related

| Type                   | Reference                                                                                                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Options declared in    | Not applicable                                                                                                                                                                                                                                         |
| Counterpart file       | `flake.nix` (the thin entry point that calls this file)                                                                                                                                                                                                |
| Profile default set in | Not applicable                                                                                                                                                                                                                                         |
| ADR                    | [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md), [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) |
| Incident               | [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md)                                                                                                          |

---

<!-- METADATA 
Module: flake/default.nix 
Context: Both (composition point for NixOS + Home Manager outputs) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->