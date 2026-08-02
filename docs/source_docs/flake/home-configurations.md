<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Standalone Home Manager Configurations — `home-configurations.nix`

> _Defines `homeConfigurations` — the standalone HM path, usable independently of `nixos-rebuild`, and shared as the confirmed-working sibling to `flake/hosts.nix`._

**Module path:** `flake/home-configurations.nix` 
**Evaluation context:** Home Manager
- standalone — *`home-manager.lib.homeManagerConfiguration`, not the NixOS module*
**Status:** Stable 
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Declares `homeConfigurations."cypher_whisperer@cypher-nixos"` via `home-manager.lib.homeManagerConfiguration`
- Consumes the shared `pkgs` *(already carrying the SSOT overlays/config, built by `flake/default.nix`)* rather than instantiating its own
- Explicitly re-imports every HM-module-contributing flake input *(currently `catppuccin`)* required by the shared `modules/home/default.nix` tree

**Does not:**

- Build its own `pkgs` or overlay list — receives `pkgs` as an argument, see [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)
- Declare `nixosConfigurations` — _see `flake/hosts.nix`_
- Run automatically as part of any other command — *this path only applies via an explicit `home-manager switch --flake .#cypher_whisperer@cypher-nixos` invocation*

---

## Evaluation Context

| Property              | Value                                                                                                                                                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Evaluated by          | `homeManagerModules`, via `home-manager.lib.homeManagerConfiguration` — an entirely separate module-system instantiation from `flake/hosts.nix`'s nested HM evaluation, even though both ultimately configure the same user |
| Options namespace     | `cypher-os.*` *(via `../modules/home/default.nix`),* plus whatever `catppuccin.homeModules.catppuccin` declares                                                                                                             |
| Imports `options.nix` | Indirectly — *`../modules/home/default.nix` pulls in the full `modules/` tree*                                                                                                                                              |
| Kill-switch guard     | None at this level — *`cypher-os.profile.desktop.enable = true;` is set directly here, same pattern as `flake/hosts.nix`*                                                                                                   |
| Profile default       | Set directly in this file, not read from a separate profile-default file                                                                                                                                                    |

---

## Block Analysis

### Block 1 — Function signature and `homeManagerConfiguration` call

**What is this?** A function of `{ inputs, pkgs }` returning an attrset whose single key, `"cypher_whisperer@cypher-nixos"`, is the result of `inputs.home-manager.lib.homeManagerConfiguration { ... }`.

**What does it do?** `homeManagerConfiguration` builds a standalone HM activation, independent of any NixOS system evaluation. The returned attrset becomes this repo's `homeConfigurations` output.

**Why is it here?** Receiving `pkgs` as an argument — the exact same value `flake/hosts.nix` receives via a parallel path, both ultimately sourced from `flake/nixpkgs-config.nix` through `flake/default.nix` — is the direct fix for the divergence that caused the `claude-desktop` bug in [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md): before this refactor, this file built its own `pkgs` from a separately-maintained overlay list.

```nix
{
  inputs,
  pkgs,
}:
{
  "cypher_whisperer@cypher-nixos" = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit inputs; self = inputs.self; };
    modules = [ ... ];
  };
}
```

---

### Block 2 — `extraSpecialArgs`

**What is this?** `extraSpecialArgs = { inherit inputs; self = inputs.self; };` — note the option name: `extraSpecialArgs`, not `specialArgs` as in `flake/hosts.nix`.

**What does it do?** Same functional role as `flake/hosts.nix`'s `specialArgs` — threads `inputs`/`self` into every module in this standalone HM evaluation.

**Why is it here?** The name difference (`extraSpecialArgs` vs `specialArgs`) isn't a typo or inconsistency to fix — it's `home-manager.lib.homeManagerConfiguration`'s actual parameter name, distinct from NixOS's `nixosSystem` parameter of the same conceptual purpose. Worth documenting explicitly since it's an easy point of confusion when working across both files.

```nix
extraSpecialArgs = { inherit inputs; self = inputs.self; };
```

---

### Block 3 — Module list: shared HM tree

**What is this?** `../modules/home/default.nix`, the first entry in `modules`.

**What does it do?** Merges the entire `cypher-os.*` HM module tree — identical to what `flake/hosts.nix`'s nested HM user block imports — into this standalone evaluation.

**Why is it here?** Using the exact same import path as `flake/hosts.nix` is what keeps the two evaluation contexts producing equivalent configurations. This is also the file where `nixpkgs.overlays`/`nixpkgs.config`/`home-manager.backupFileExtension` used to be duplicated as a workaround (per [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)) — that duplication has been removed; `modules/home/default.nix` itself is now identical in content regardless of which context imports it.

```nix
../modules/home/default.nix
```

---

### Block 4 — `catppuccin.homeModules.catppuccin` re-import

**What is this?** `inputs.catppuccin.homeModules.catppuccin`, listed explicitly as its own `modules` entry.

**What does it do?** Loads Catppuccin's HM module — the option declarations (`catppuccin.*`) that `modules/apps/editor/vscode.nix` and others read.

**Why is it here?** This is the single most important block in this file to understand, and it's documented at length in the source itself: declaring a flake input does not make its HM modules available automatically in every HM evaluation context — each context (`flake/hosts.nix`'s nested evaluation vs. this file's standalone one) is an independent module-system instantiation, and a module imported in one is invisible to the other unless re-imported explicitly. This was discovered via a silent, no-symptom-until-directly-evaluated failure (`nix eval .#homeConfigurations."cypher-whisperer@cypher-nixos".config.programs.direnv.enable` erroring with `"The option 'catppuccin' does not exist"`), predating and structurally identical to the `claude-desktop` overlay divergence in [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) — the same "two contexts silently diverge" pattern, just for HM-module imports instead of overlays. The checklist for any future HM-module-contributing flake input is: (1) add to flake inputs, (2) import in `flake/hosts.nix`'s HM user block, (3) import here. Skipping step 3 reproduces this exact failure mode.

```nix
inputs.catppuccin.homeModules.catppuccin
```

---

### Block 5 — Identity block

**What is this?** An inline module setting `home.username`, `home.homeDirectory`, and `cypher-os.profile.desktop.enable = true;`.

**What does it do?** Establishes this standalone HM evaluation's identity and activates the desktop profile — functionally identical to Block 6 of `flake/hosts.nix`.

**Why is it here?** Duplicated (not derived) from the `flake/hosts.nix` equivalent, for the same reason `home.username`/`home.homeDirectory` there aren't derived from NixOS's `users.users.*` — Home Manager's standalone evaluation has no path back to either the NixOS system config or the other HM evaluation context. Both must be kept manually in sync; this is a known, accepted asymmetry (see Known Limitations).

```nix
{
  home.username = "cypher_whisperer";
  home.homeDirectory = "/home/cypher-whisperer";
  cypher-os.profile.desktop.enable = true;
}
```

---

### Block 6 — Commented future-host template

**What is this?** A commented-out `"cypher_whisperer@arch"` entry.

**What does it do?** Nothing currently — inert documentation of the pattern for adding a future non-NixOS lens (Arch, per the multi-lens architecture).

**Why is it here?** Carried forward unchanged from the pre-refactor `flake.nix` — DEFERRED-tier per this repo's comment convention, kept as a ready-to-use template rather than removed, since the multi-lens architecture is a stated long-term goal.

```nix
# "cypher_whisperer@arch" = inputs.home-manager.lib.homeManagerConfiguration {
#   inherit pkgs;
#   extraSpecialArgs = { inherit inputs; self = inputs.self; };
#   modules = [
#     ../hosts/arch/home.nix
#     { home.username = "cypher_whisperer"; home.homeDirectory = "/home/cypher-whisperer"; }
#   ];
# };
```

---

## Dependencies

**Imported files:**

- `../modules/home/default.nix` — shared HM module tree

**NixOS options set by this file:** Not applicable — this is a standalone HM evaluation, no NixOS options exist in this context

**Home Manager options set by this file:**

- `home.username`, `home.homeDirectory`, `cypher-os.profile.desktop.enable`

**nixpkgs packages required:** None directly — receives a pre-built `pkgs` as an argument

**External flake inputs used:**

- `inputs.home-manager` (`.lib.homeManagerConfiguration`)
- `inputs.catppuccin` (`.homeModules.catppuccin`)
- `inputs.self`

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.profile.desktop.enable`|`bool`|set `true` here|Cascades every app/DE/DM default under the desktop profile — identical effect to the same option set in `flake/hosts.nix`|

_All other `cypher-os.*` options are declared and documented within `modules/` — see `modules/home/default.nix`'s documentation._

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

_Block 6 (the commented `"cypher_whisperer@arch"` entry) is DEFERRED-tier — retained as a template, not yet needed while only one host/lens is live._

---

## Design Notes

- This file and `flake/hosts.nix` are structurally parallel but deliberately _not_ merged or cross-referencing each other at the Nix level — each independently receives `pkgs`/`inputs` from `flake/default.nix` and independently declares its identity block. The alternative (deriving this file's config from `flake/hosts.nix`'s) was considered and rejected in [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) specifically to keep this path usable for genuinely non-NixOS hosts later, which would have no `nixosConfigurations` entry to derive from.
  
- Block 4's re-import requirement is the most likely place a future contributor introduces a repeat of INC_001's failure class — flagged prominently here and in the source comment for that reason.

_See [ADR_011_2026_07_31](../../project/decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md) and [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) for the full decision records._

---

## Known Limitations

- `home.username`/`home.homeDirectory` (Block 5) are a manual duplicate of `flake/hosts.nix`'s equivalent, with no automated consistency check between them
  
- Any future HM-module-contributing flake input (beyond `catppuccin`) requires manual addition to both this file and `flake/hosts.nix`'s HM user block — no mechanism currently prevents a repeat of the exact failure this file's Block 4 comment describes
  
- `home-manager.backupFileExtension` *(a NixOS-module-only option, set in `flake/hosts.nix`)* has no equivalent here — backup behavior for this path is controlled entirely by the `-b <ext>` CLI flag at invocation time *(e.g. `home-manager switch -b hm-bk --flake .#...`),* not by anything in this file

---

## Related

| Type                   | Reference                                                                                                                                                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Options declared in    | `../modules/options.nix` (and throughout `modules/`)                                                                                                                                                                                     |
| Counterpart file       | `flake/hosts.nix` (the NixOS-integrated equivalent)                                                                                                                                                                                      |
| Profile default set in | Set directly in this file's Block 5, not a separate profile-default file                                                                                                                                                                 |
| ADR                    | [ADR_011_2026_07_31](../../project/decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md), [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) |
| Incident               | [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md)                                                                                            |

---

<!-- METADATA 
Module: flake/home-configurations.nix 
Context: Home Manager (standalone) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->