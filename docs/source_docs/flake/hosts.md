<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# NixOS System Configurations — `hosts.nix`

> _Defines `nixosConfigurations` — the bootable NixOS system(s), with Home Manager wired in as a NixOS module._

**Module path:** `flake/hosts.nix` 
**Evaluation context:** NixOS system:
- with an embedded Home Manager evaluation for `home-manager.users.cypher_whisperer`
**Status:** Stable
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Declares `nixosConfigurations.cypher-nixos` via `nixpkgs.lib.nixosSystem`
- Wires the SSOT overlays/`nixpkgs.config` *(from `flake/nixpkgs-config.nix`, passed in as arguments)* into the system's `nixpkgs.overlays`/`nixpkgs.config`
- Imports the host's system-level config *(`hosts/nixos/configuration.nix`)*
- Integrates `home-manager.nixosModules.home-manager` and declares the per-user HM config for `cypher_whisperer`

**Does not:**

- Declare the overlay/config values themselves — *see `flake/nixpkgs-config.nix`*
- Declare `homeConfigurations` (the standalone HM path) — *see `flake/home-configurations.nix`*
- Contain any host-specific hardware or desktop-environment configuration directly — *that lives in `hosts/nixos/configuration.nix` and the `modules/` tree it imports*

---

## Evaluation Context

| Property              | Value                                                                                                                                                              |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Evaluated by          | `nixosModules` (via `nixpkgs.lib.nixosSystem`), with a nested Home Manager module evaluation for the `home-manager.users.cypher_whisperer` block                   |
| Options namespace     | `nixpkgs.*`, `home-manager.*` (NixOS-module options), and — inside the nested HM user block — `cypher-os.*` (via its `imports`)                                    |
| Imports `options.nix` | Indirectly — `../modules/home/default.nix` *(imported inside the HM user block)* pulls in the full `modules/` tree, which includes every `options.nix` in the repo |
| Kill-switch guard     | None at this level — this file is the entry point that other kill-switches *(`cypher-os.profile.desktop.enable`, etc.)* are set from, not itself guarded           |
| Profile default       | `cypher-os.profile.desktop.enable = true;` is set directly in the HM user block here, not read from a separate profile default file                                |

---

## Block Analysis

### Block 1 — Function signature and `nixosSystem` call

**What is this?** A function of `{ inputs, system, nixpkgsOverlays, nixpkgsConfig }` returning an attrset whose single key, `cypher-nixos`, is the result of `inputs.nixpkgs.lib.nixosSystem { ... }`.

**What does it do?** `nixosSystem` builds a complete, evaluable NixOS system closure from the `modules` list passed to it. The returned attrset is assigned directly as this repo's `nixosConfigurations` output by `flake/default.nix`.

**Why is it here?** Taking `nixpkgsOverlays`/`nixpkgsConfig` as explicit arguments (rather than importing `flake/nixpkgs-config.nix` directly inside this file) keeps this file free of any dependency on _how_ the SSOT values are produced — `flake/default.nix` owns that wiring, and this file only needs to know it will receive them. This is what lets `flake/home-configurations.nix` receive the same values through a parallel, independent argument list without either file referencing the other.

```nix
{
  inputs,
  system,
  nixpkgsOverlays,
  nixpkgsConfig,
}:
{
  cypher-nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; self = inputs.self; };
    modules = [ ... ];
  };
}
```

---

### Block 2 — `specialArgs`

**What is this?** `specialArgs = { inherit inputs; self = inputs.self; };`, passed to `nixosSystem`.

**What does it do?** Threads `inputs` (and `self`) into every NixOS module in this configuration's evaluation, including `hosts/nixos/configuration.nix` and any module it transitively imports. This is what makes `inputs.claude-desktop.overlays.default`-style references resolvable inside those files without each one importing the flake directly.

**Why is it here?** `specialArgs` (as opposed to ordinary module arguments) is required specifically because these values need to be available to modules that are merged in via `imports`, before the module system has finished resolving the config that would otherwise supply them — this is the standard NixOS mechanism for exactly that need.

```nix
specialArgs = { inherit inputs; self = inputs.self; };
```

---

### Block 3 — Overlay/config injection module

**What is this?** An inline, unnamed module (`{ nixpkgs.overlays = nixpkgsOverlays; nixpkgs.config = nixpkgsConfig; }`) as the first entry in `modules`.

**What does it do?** Sets the NixOS system's own `pkgs` instantiation to use the SSOT overlay list and config, before any other module in the list is evaluated.

**Why is it here?** Position matters here only in that it must be present in `modules` at all — NixOS module evaluation is not strictly order-dependent for option-setting, but placing it first documents that this is foundational, applying-before-everything-else configuration rather than an incidental setting. This block is the direct replacement for what used to be inline in `flake.nix` and duplicated in `hosts/nixos/configuration.nix` — see [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md).

```nix
{
  nixpkgs.overlays = nixpkgsOverlays;
  nixpkgs.config = nixpkgsConfig;
}
```

---

### Block 4 — Host system import

**What is this?** `../hosts/nixos/configuration.nix` in the `modules` list.

**What does it do?** Merges the host's actual system configuration — hardware, boot, user accounts, desktop environment, and every `modules/*/system.nix` it transitively imports — into this `nixosSystem` evaluation.

**Why is it here?** Keeping the host definition in `hosts/nixos/configuration.nix` rather than inlining it here preserves the separation between "how this flake composes its outputs" (`flake/`) and "what this specific host actually contains" (`hosts/`) — the latter is what would need duplicating if/when a second NixOS host is added, the former would not.

```nix
../hosts/nixos/configuration.nix
```

---

### Block 5 — Home Manager NixOS-module integration

**What is this?** `inputs.home-manager.nixosModules.home-manager`, followed by an inline module setting `home-manager.{useGlobalPkgs,useUserPackages,extraSpecialArgs,users,backupFileExtension}`.

**What does it do?** Integrates Home Manager into this system's activation: `useGlobalPkgs = true` makes HM use this same `pkgs` (carrying the SSOT overlays) instead of building its own; `useUserPackages = true` installs `home.packages` via `/etc/profiles/per-user/cypher_whisperer` rather than `~/.nix-profile`, independent of whether the HM activation script itself succeeds (see Known Limitations); `extraSpecialArgs` mirrors Block 2's `specialArgs` for the HM module tree; `users.cypher_whisperer` is the actual per-user HM configuration; `backupFileExtension = "hm-bak"` governs conflicting-file handling on activation.

**Why is it here?** This is the concrete implementation of [ADR_011_2026_07_31](../../project/decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md) — HM stays wired into `nixos-rebuild switch` via this exact block rather than being removed in favor of a standalone-only setup.

```nix
inputs.home-manager.nixosModules.home-manager
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit inputs; self = inputs.self; };
  home-manager.users.cypher_whisperer = { config, pkgs, lib, ... }: { ... };
  home-manager.backupFileExtension = "hm-bak";
}
```

---

### Block 6 — Per-user HM config body

**What is this?** The function body of `home-manager.users.cypher_whisperer` — an `imports` list plus `home.username`, `home.homeDirectory`, and `cypher-os.profile.desktop.enable = true;`.

**What does it do?** `imports` pulls in `../modules/home/default.nix` (the full `cypher-os.*` HM module tree, including `modules/home/gc-hm.nix`) and `inputs.catppuccin.homeModules.catppuccin` (needed explicitly in every HM evaluation context per the pattern documented in `flake/home-configurations.nix`). `home.username`/`home.homeDirectory` establish HM's own identity for this user, matching (but not automatically derived from) the `users.users.cypher_whisperer` declaration in `hosts/nixos/configuration.nix`. The profile toggle cascades every app/DE/DM default declared under the `cypher-os.profile.desktop` namespace.

**Why is it here?** `home.username`/`home.homeDirectory` must be set independently here rather than inherited from the NixOS `users.users.*` declaration — Home Manager's module system has no automatic link to NixOS's, even when `useGlobalPkgs`/`useUserPackages` are both `true`; this is a real, easy-to-miss duplication point flagged for the rename in [ADR_014_2026_07_31](../../project/decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md).

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/home/default.nix
    inputs.catppuccin.homeModules.catppuccin
  ];
  home.username = "cypher_whisperer";
  home.homeDirectory = "/home/cypher-whisperer";
  cypher-os.profile.desktop.enable = true;
}
```

---

## Dependencies

**Imported files:**

- `../hosts/nixos/configuration.nix` — host system config
- `../modules/home/default.nix` (via the HM user block) — HM module tree, including `options.nix` throughout `modules/`

**NixOS options set by this file:**

- `nixpkgs.overlays`, `nixpkgs.config` — from the SSOT arguments
- `home-manager.useGlobalPkgs`, `home-manager.useUserPackages`, `home-manager.extraSpecialArgs`, `home-manager.users.cypher_whisperer`, `home-manager.backupFileExtension`

**Home Manager options set by this file:** _(within the nested `home-manager.users.cypher_whisperer` block)_

- `home.username`, `home.homeDirectory`, `cypher-os.profile.desktop.enable`

**nixpkgs packages required:** None directly

**External flake inputs used:**

- `inputs.nixpkgs` (`.lib.nixosSystem`)
- `inputs.home-manager` (`.nixosModules.home-manager`)
- `inputs.catppuccin` (`.homeModules.catppuccin`)
- `inputs.self`


---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.profile.desktop.enable`|`bool`|set `true` here|Cascades every app/DE/DM default under the desktop profile for `cypher_whisperer`'s HM config|

_All other `cypher-os.*` options are declared and documented within the `modules/` tree this file imports, not here — see `modules/home/default.nix`'s documentation for the entry point._

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

_The commented-out example overrides block (`cypher-os.de.gnome.enable = false;` etc.) in Block 6 is DEFERRED-style — present as a documented, ready-to-use override point, not currently active._

---

## Design Notes

- `home.homeDirectory = "/home/cypher-whisperer"` intentionally does not match `home.username = "cypher_whisperer"` as of the [username string change](../../project/decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md) — this is deliberate, not a leftover bug; see that ADR for why the directory path was kept stable.
- The overlay/config injection module (Block 3) and the SSOT file it draws from are two different files by design, not merged into one — `flake/nixpkgs-config.nix` stays a pure-data file importable from anywhere, while this file is specifically about _how NixOS consumes_ that data.

_See [ADR_011_2026_07_31](../../project/decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md) and [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) for the full decision records._

---

## Known Limitations

- `home-manager.useUserPackages = true` means `home.packages` are delivered via a system-activation-time profile independent of the `home-manager-cypher_whisperer.service` activation script's success — a failed HM activation does not block package installation, which was the core diagnostic trap in [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md). Package presence after a rebuild is not evidence HM fully applied; check `systemctl status` on the unit directly.
  
- `home.username`/`home.homeDirectory` here and `users.users.cypher_whisperer`'s equivalents in `hosts/nixos/configuration.nix` are two independent declarations with no automatic consistency check — a mismatch would likely surface as confusing runtime behavior rather than a clear evaluation error.

---

## Related

| Type                   | Reference                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Options declared in    | `../modules/options.nix` (and throughout `modules/`)                                                                                                                                                                                                                                                                                                                                                                                                              |
| Counterpart file       | `flake/home-configurations.nix` (the standalone equivalent)                                                                                                                                                                                                                                                                                                                                                                                                       |
| Profile default set in | Set directly in this file's Block 6, not a separate profile-default file                                                                                                                                                                                                                                                                                                                                                                                          |
| ADR                    | [ADR_011](../../project/decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md), [ADR_012](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md), [ADR_013](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md), [ADR_014](../../project/decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md) |
| Incident               | [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md)                                                                                                                                                                                                                                                                                                                     |

---

<!-- METADATA 
Module: flake/hosts.nix 
Context: NixOS (with nested Home Manager evaluation) 
Created: 2026-07-31 
Updated: 2026-07-31 
-->