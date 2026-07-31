# ADR-005: Module Architecture — The Three-File Split Convention

**Date:** 2026-04-16
**Status:** Accepted
**Deciders:** CypherWhisperer
**Related:** [ADR-001 — Namespace Design](ADR_001_cypher-os_namespace_design.md), [ADR-002 — GNOME Module Isolation](ADR_002_gnome_module_isolation.md) _(ADR-002 is the concrete first application of this convention. This ADR formalizes it as the system-wide rule.)_

---

## Context

The GNOME module isolation work ([ADR-002](ADR_002_gnome_module_isolation.md)) surfaced a problem that was not specific to GNOME — _it was systemic._ NixOS modules and Home Manager modules share the same option namespace (`cypher-os.*`) but run in **separate evaluation contexts**. A module that declares options and sets system-level config (`environment.systemPackages`, `services.*`) in the same file causes HM to choke when it encounters NixOS-only attributes. A module that declares options and sets HM-level config (_`home.*`, `dconf.*`, `gtk.*`_) in the same file causes NixOS to choke on HM-only attributes.

The GNOME split resolved this for one module group. But as the namespace grows — _`devops`, `virtualisation`, `gaming`, `dm`, `de/plasma`, `de/hyprland`_ — the same problem recurs in every module group. The solution had to be a **convention**, not a one-off fix.

The additional complication: options declared in one evaluation context must also be visible in the other. If `cypher-os.de.gnome.enable` is declared only in the HM evaluation graph, `system.nix` (_evaluated in the NixOS graph_) cannot read it in a `lib.mkIf`. Options are the shared interface between both evaluation graphs.

---

## Decision

Every module group that touches both Home Manager and NixOS follows a **three-file split**: `options.nix` (_declarations only_), `hm.nix` (_HM config_), `system.nix` (_NixOS config_). A `default.nix` shim acts as the HM entry point for the group. Option declarations live in `options.nix` exclusively and are imported by both `default.nix` (_HM path_) and `system.nix` (_NixOS path_).

---

## Reasoning

The core insight is this:

```
HM evaluation graph                   NixOS evaluation graph
────────────────────                  ──────────────────────
default.nix                           configuration.nix
  └─ imports options.nix   ────────►    option exists in config.*
  └─ imports hm.nix                     └─ system.nix reads config.*
       └─ home.*, dconf.*                    └─ services.*, environment.*
          gtk.*, lib.hm.*                       virtualisation.*, programs.*
```

Options are the **shared interface**. HM owns the declarations and default values via `options.nix`. NixOS owns the consequences of those values via `system.nix`. Both graphs import `options.nix` so the option exists in both evaluation contexts before any `lib.mkIf` fires.

**The four invariants — no exceptions:**

1. **Options are declared once, in `options.nix`.** Never in `default.nix`, `hm.nix`, `system.nix`, or sub-module files.
2. **`system.nix` always imports `./options.nix`.** This makes options available in the NixOS evaluation context.
3. **`default.nix` never contains NixOS-only attributes.** No `services.*`, `environment.*`, `virtualisation.*`. HM will choke.
4. **Inner modules always check both parent and self.** `lib.mkIf (parent.enable && self.enable)` is the kill switch mechanism.

---

## The Convention — File by File

### `options.nix`

**Purpose:** Declare every `cypher-os.*` option for this group. No `config` block. No packages. No services. Just option shapes.

**Imported by:** `default.nix` (_HM path_) AND `system.nix` (_NixOS path_).

**Why both:** Options must exist in whichever evaluation context references them. Importing `options.nix` in both files ensures the option is declared before any `lib.mkIf` tries to read it, regardless of which graph is evaluating.

```nix
# modules/<group>/options.nix
{ lib, ... }:
{
  options.cypher-os.<group> = {
    enable = lib.mkEnableOption "...";
    sub-feature.enable = lib.mkEnableOption "...";
  };
}
```

---

### `default.nix`

**Purpose:** HM entry point for the group. A pure shim — _no options, no config of its own._

**Imported by:** `modules/home/default.nix` unconditionally.

**Why a shim:** HM needs both the option declarations (_available before anything references them_) and the HM-level config (`hm.nix`). `default.nix` wires both in without containing either.

```nix
# modules/<group>/default.nix
{ ... }:
{
  imports = [
    ./options.nix
    ./hm.nix       # omit if the group has no HM-level config
  ];
}
```

---

### `hm.nix`

**Purpose:** Everything that belongs to the user's home environment.

**Imported by:** `default.nix`, evaluated in the HM context.

**Belongs here:** `home.packages`, `programs.*` (HM programs), `dconf.settings`, `gtk.*`, `lib.hm.*`, `xdg.*`, per-user service config.

**Does NOT belong here:** `services.*` (system daemons), `environment.systemPackages`, `virtualisation.*`, `hardware.*`.

```nix
# modules/<group>/hm.nix
{ config, pkgs, lib, ... }:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.cypher-os.<group>.enable {
    home.packages = with pkgs; [ ... ];
    dconf.settings = { ... };
    programs.<foo>.enable = true;
  };
}
```

---

### `system.nix`

**Purpose:** Everything that requires root or system-level context.

**Imported by:** `hosts/nixos/configuration.nix` directly.

**Belongs here:** `services.*`, `environment.systemPackages`, `virtualisation.*`, `hardware.*`, `networking.*`, system-level `programs.*`.

**Does NOT belong here:** `home.*`, `dconf.*`, `gtk.*`, `lib.hm.*`.

```nix
# modules/<group>/system.nix
{ config, pkgs, lib, ... }:
{
  imports = [ ./options.nix ];   # ← critical: declares options in NixOS context

  config = lib.mkIf config.cypher-os.<group>.enable {
    services.<foo>.enable = true;
    environment.systemPackages = with pkgs; [ ... ];
  };
}
```

---

## Kill Switch Pattern

Every group has a master `enable` option. Sub-options sit beneath it. The kill switch works through guard conditions in each sub-module — not through option value propagation.

```nix
# Inner module — always checks parent AND self
config = lib.mkIf (
  config.cypher-os.<group>.enable &&
  config.cypher-os.<group>.<sub>.enable
) { ... };
```

Setting `cypher-os.<group>.enable = false` disables everything beneath it because every inner module's guard requires the parent to be true.

Sub-option defaults live in `modules/profile/default.nix`:

```nix
# profile/default.nix — desktop profile block
cypher-os.devops.enable            = lib.mkDefault true;
cypher-os.devops.containers.enable = lib.mkDefault true;
cypher-os.devops.kubernetes.enable = lib.mkDefault true;
```

`lib.mkDefault` means any explicit assignment in `configuration.nix` always wins.

### The `apps` Kill Switch — A Special Case

`cypher-os.apps.enable` is a true emergency kill-all switch. It defaults to `true` — most users never touch it. Its purpose is as a last-resort _"disable everything"_ switch (e.g. on a truly minimal ISO or rescue environment). Individual app groups are controlled by their own `enable` options. Profiles set those group options via `lib.mkDefault`.

```nix
# modules/apps/options.nix
{ lib, ... }:
{
  options = {
    cypher-os.apps.enable = lib.mkEnableOption "CypherOS application layer" // {
      # Override mkEnableOption's default of false → make it default true.
      default = true;
    };
  };
}
```

---

## Module Groups Reference

### `modules/profile/`

```
profile/
├── options.nix   — declares cypher-os.profile.{desktop,server}.enable
└── default.nix   — HM shim + sets all group lib.mkDefault values
```

**Role:** Meta-switches. Enabling a profile cascades `lib.mkDefault` values across all groups. Individual overrides in `configuration.nix` always beat `lib.mkDefault`.

---

### `modules/de/<de>/` (e.g. `gnome`)

```
de/gnome/
├── options.nix   — declares cypher-os.de.gnome.enable
├── default.nix   — imports options.nix + hm.nix
├── hm.nix        — dconf.settings, gtk.*, lib.hm.gvariant.*, home.packages
└── system.nix    — services.desktopManager.gnome.enable, environment.gnome.excludePackages
```

**Boundary:** `lib.hm.*` and `dconf` are HM-only. `services.desktopManager` is NixOS-only. Never mix in the same file.

---

### `modules/dm/<dm>/` (e.g. `gdm`)

```
dm/gdm/
├── options.nix   — declares cypher-os.dm.gdm.enable
├── default.nix   — imports options.nix
└── system.nix    — services.displayManager.gdm.{enable,wayland}
```

**Note:** GDM has no HM-level config, so no `hm.nix`. `default.nix` only imports `options.nix`.

---

### `modules/devops/`

```
devops/
├── options.nix     — declares cypher-os.devops.{enable,containers,kubernetes,databases,iac,secrets}.enable
├── default.nix     — imports options.nix (HM shim only — no devops HM config)
├── system.nix      — pure router: imports all sub-modules
├── containers.nix  — Docker, Podman; guards on devops.enable && devops.containers.enable
├── kubernetes.nix  — k3s, kubectl, Helm; same guard pattern
├── databases.nix   — PostgreSQL, Redis; same guard pattern
├── iac.nix         — Terraform, OpenTofu, Ansible, Pulumi; same guard pattern
├── cicd.nix            — CI/CD tooling (act, gh, actionlint, github-runner)
├── cloud.nix           — Cloud Computing workflow tooling (AWS, AZURE, GCS)
├── observability.nix   — Observability workflow tools(prometheus, grafana, loki)
├── networking.nix      — Traefik + Caddy
└── secrets.nix         — sops, age, gnupg, vault; same guard pattern
```

**Note:** All devops config is system-level (daemons, services). No `hm.nix` needed. `system.nix` is a pure router with no `config` block — each sub-module self-guards.

---

### `modules/virtualisation/`

```
virtualisation/
├── options.nix   — declares cypher-os.virtualisation.helpers.enable
├── default.nix   — imports options.nix (HM shim only)
└── system.nix    — virtualisation.libvirtd, environment.systemPackages (virt tools)
```

---

### `modules/gaming/`

```
gaming/
├── options.nix     — declares cypher-os.gaming.{enable,steam,minecraft}.enable
├── default.nix     — imports options.nix + any HM-level gaming config
└── system.nix      — Steam system packages, hardware.steam-hardware.enable
```

---

### `modules/apps/<group>/`

Apps are exclusively HM-level — no system daemons. They follow a simplified variant of the pattern:

```
apps/<group>/
├── options.nix     — declares all options for the group and its sub-tools
├── default.nix     — imports options.nix + hm.nix + all sub-tool modules
├── hm.nix          — group-level mkIf block: sets sub-tool mkDefaults + home.packages
└── <tool>.nix      — per-tool HM config (programs.<tool>.*); guards on group.enable && self.enable
```

No `system.nix` for apps — they are entirely home environment config.

Sub-tool modules carry no `options` block — all declarations live in `options.nix`:

```nix
# apps/cli/htop.nix
{ config, lib, ... }:
{
  # No options block — declared in options.nix
  config = lib.mkIf (
    config.cypher-os.apps.cli.enable &&
    config.cypher-os.apps.cli.htop.enable
  ) {
    programs.htop = { ... };
  };
}
```

---

## The HM Root — `modules/home/default.nix`

Unconditionally imports every module that declares `cypher-os.*` options. This is what makes all options available to HM before any `lib.mkIf` fires.

```nix
{ ... }:
{
  imports = [
    ../profile
    ../de
    ../dm
    ../apps
    ../gaming
    ../devops
    ../virtualisation
  ];

  home.stateVersion = "24.11";
}
```

**Rule:** Every directory listed here must resolve to a `default.nix` that is a pure shim — `options.nix` + optional `hm.nix`. No system config, no `environment.*`, no `services.*` anywhere in the HM import chain. HM will choke if it encounters NixOS-only attributes.

---

## The NixOS Root — `hosts/nixos/configuration.nix`

Imports `system.nix` files directly. Never imports `default.nix` of module groups — that is HM territory.

```nix
imports = [
  ./hardware-configuration.nix
  ../../modules/users/cypher-whisperer.nix
  ../../modules/profile/options.nix        # makes cypher-os.profile.* available to NixOS
  ../../modules/de/gnome/system.nix
  ../../modules/dm/gdm/system.nix
  ../../modules/devops/system.nix
  ../../modules/virtualisation/system.nix
  ../../modules/gaming/steam-system.nix
];
```

---

## Scaling the Convention — Adding New Modules

**When adding a new module group:**

1. Create `modules/<group>/options.nix` — declare all `cypher-os.<group>.*` options here first.
2. Create `modules/<group>/default.nix` — shim that imports `options.nix` and `hm.nix`.
3. Create `modules/<group>/hm.nix` if there is any HM-level config (`home.*`, `dconf.*`, `gtk.*`).
4. Create `modules/<group>/system.nix` if there is any system-level config (`services.*`, `environment.*`). Always `imports = [ ./options.nix ]` at the top.
5. Add the group directory to `modules/home/default.nix` imports.
6. Add `system.nix` to `hosts/nixos/configuration.nix` imports.
7. Add `lib.mkDefault` values to `modules/profile/default.nix` under the appropriate profile block.

**When adding a sub-feature to an existing group:**

1. Add its option to the group's `options.nix` — _nowhere else._
2. Create the sub-module file. No `options` block — _only a `config = lib.mkIf (parent.enable && self.enable)` block._
3. Import the sub-module from `system.nix` or `default.nix` depending on scope.
4. Add its `lib.mkDefault` to `profile/default.nix`.

---

## Alternatives Considered

### Single file per module group with conditional blocks

A single `gnome.nix` containing both `home.*` and `services.*` behind `lib.mkIf` guards. This is the original state before this ADR. It works for a single DE but fails as soon as the file is evaluated in the wrong context — _HM sees `services.*` and errors, NixOS sees `dconf.*` and errors._ Not viable at scale.

### Separate flake outputs per context (HM flake + NixOS flake)

Splitting the repository into a HM flake and a NixOS flake entirely eliminates the shared-context problem. The cost is that you now maintain two repositories (_or two flake outputs_) that must be kept in sync, and options cannot be shared across them without a third shared library. Significantly more complexity for a single-user setup.

### `mkIf` everything at the flake level

Conditionally importing entire module files based on profile at the `flake.nix` level. This avoids the evaluation-context problem by never loading a module that doesn't apply. The cost is that `flake.nix` becomes the configuration logic layer — _it needs to know about every profile's module list._ The current design keeps `flake.nix` as a pure entry point and pushes all logic into the module system where it belongs.

---

## Consequences

**Positive:**

- The layering conflict is resolved permanently. HM and NixOS each see exactly what they should see.
- Every new module group has a clear, unambiguous template to follow. Adding Plasma is the same mechanical steps as adding Hyprland is the same steps as adding any future group.
- Options are declared once. Any file that needs to reference a `cypher-os.*` option knows exactly where it is declared (`options.nix`) and that it will be available in both evaluation contexts.
- Kill switches work cleanly at every level of the hierarchy without any special logic.

**Negative / Trade-offs:**

- A module group that previously lived in one file now lives in four. The four-file structure is a fixed overhead per group — _it does not grow with complexity within the group._
- New contributors need to understand the two-evaluation-context model before the structure makes intuitive sense. This document and the ADR-002 worked example are the onboarding path.

**Neutral / Operational:**

- `default.nix` files are Home Manager territory. `system.nix` files are NixOS territory. This maps cleanly to the `nixos-rebuild switch` (NixOS path) and `home-manager switch` (HM path) commands.
- The four invariants must hold everywhere without exception. Any deviation — options declared outside `options.nix`, system config inside `default.nix` — breaks evaluation in ways that produce confusing error messages. The invariants are defensive.
