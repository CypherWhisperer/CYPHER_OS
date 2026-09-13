<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Productivity HM — `hm.nix`

> _Home Manager activation layer for the productivity group: sets app-level enable defaults and installs the broader package set that has no dedicated sub-module._

**Module path:** `modules/apps/productivity/hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-10`

---

## Responsibility

**Does:**

- Guards all configuration behind a two-condition `lib.mkIf` that requires both `cypher-os.apps.enable` and `cypher-os.apps.productivity.enable`
- Sets `lib.mkDefault true` on `claude.enable`, `obsidian.enable`, and `penpot.enable` so that enabling the productivity group activates all three apps unless explicitly overridden
- Installs the broader productivity package set — _design tools, office suite, creative suite, media players, communication clients_ — into the user profile via `home.packages`

**Does not:**

- Configure any of the three sub-module apps (_Claude, Obsidian, Penpot_) — _each has its own dedicated module_
- Manage system-level concerns — _no NixOS options are touched here_
- Declare any `cypher-os.*` options — _those live in `options.nix`_

---

## Evaluation Context

| Property              | Value                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------- |
| Evaluated by          | `homeManagerModules`                                                                              |
| Options namespace     | `cypher-os.apps.productivity`                                                                     |
| Imports `options.nix` | No — _`options.nix` is imported by `default.nix`, which imports both this file and `options.nix`_ |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.productivity.enable)`            |
| Profile default       | This file IS where `lib.mkDefault` is set for all three app-level options                         |

---

## Block Analysis

---

### Block 1 — Kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset. The condition is the logical AND of two option reads: `cypher-os.apps.enable` (the top-level apps group switch, declared upstream) and `cypher-os.apps.productivity.enable` (this group's switch, declared in `options.nix`).

**What does it do?** When either condition is `false`, the entire block evaluates to `{}` — no packages are installed, no defaults are set, and no sub-module options are touched. When both are `true`, the full config block is passed to the HM evaluator.

**Why is it here?** The two-level guard — top-level apps group AND productivity subgroup — means the productivity group can be disabled independently of other app groups without touching the top-level switch. This is the standard CypherOS guard pattern for group-level HM modules.

```nix
config = lib.mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.productivity.enable) {
  ...
};
```

---

### Block 2 — App-level `lib.mkDefault` enables

**What is this?** Three `cypher-os.apps.productivity.<app>.enable = lib.mkDefault true` assignments inside the guarded `config` block.

**What does it do?** `lib.mkDefault` sets the option value at priority 1000 — lower than any explicit user assignment (priority 100) or `lib.mkForce` (priority 50). The effect is: when the productivity group is enabled, all three app sub-modules (Claude, Obsidian, Penpot) activate automatically unless a higher-priority assignment overrides them. A user wishing to disable just Obsidian while keeping the rest can write `cypher-os.apps.productivity.obsidian.enable = false` anywhere in their configuration and it will take precedence.

**Why is it here?** This is the central place where "enabling productivity" is given a concrete, opinionated meaning: it means all three apps are on. Without these defaults, enabling the group switch would install the `home.packages` set but leave Claude, Obsidian, and Penpot disabled — _their `mkIf` guards would short-circuit on the app-level enable being `false`._ The defaults bridge the gap between the group switch and the app-level switches.

This block is a known area of planned improvement. The current pattern — _child options being set inside an `mkIf` that already guards on the parent_ — is functional but not the most expressive way to model group membership. A future CypherOS session is planned to introduce assertions and a more decisive, centralised profile management approach across the entire namespace.

```nix
cypher-os.apps.productivity.claude.enable   = lib.mkDefault true;
cypher-os.apps.productivity.obsidian.enable = lib.mkDefault true;
cypher-os.apps.productivity.penpot.enable   = lib.mkDefault true;
```

---

### Block 3 — `home.packages`

**What is this?** A `home.packages` assignment using `with pkgs;` to install a list of packages into the user profile. These are productivity packages that have no dedicated CypherOS sub-module — _they require no per-app configuration management, only installation._

**What does it do?** Each listed package is installed into the user's Home Manager profile at activation time. Packages are grouped into five logical categories with inline comments:

- **System Design** — _`drawio` (diagramming), `staruml` (UML modelling)_
- **Office Suite** — _`libreoffice`_
- **Creative Suite** — _`gimp`, `inkscape`, `blender`, `krita`, `kdePackages.kdenlive`, `audacity`, `obs-studio`, `figma-agent`._ `houdini` is commented out (EXCLUDED — _It's implementation is planned, though not yet done._).
- **Media** — `vlc`, `spotify`, `clapper`
- **Communication** — `discord`, `whatsapp-electron`, `whatsapp-chat-exporter`, `telegram-desktop`, `signal-desktop`

`n8n` is commented out with a note that it is now handled by `modules/devops/n8n.nix` — _it was migrated to a dedicated module as its setup grew beyond a bare package install._

**Why is it here?** This is the correct location for packages that need to be present when the productivity group is enabled but don't warrant a dedicated module (_no config files to manage, no system-level concerns, no sub-option_). Keeping them here rather than scattered across multiple files means there is a single auditable list of "_everything installed as part of the productivity group._"

```nix
home.packages = with pkgs; [
  # ── System Design ──────────────────────────────────────────────────────
  drawio
  staruml

  # ── Office Suite ───────────────────────────────────────────────────────
  libreoffice

  # ── Creative Suite ─────────────────────────────────────────────────────
  # houdini  # EXCLUDED
  gimp
  inkscape
  blender
  krita
  kdePackages.kdenlive
  audacity
  obs-studio
  figma-agent

  # ── Media ──────────────────────────────────────────────────────────────
  vlc
  spotify
  clapper

  # ── Communication ──────────────────────────────────────────────────────
  discord
  whatsapp-electron
  whatsapp-chat-exporter
  signal-desktop
  telegram-desktop

  # ── Workflow and Automation ────────────────────────────────────────────
  # n8n  # now handled by modules/devops/n8n.nix
];
```

---

## Dependencies

**Imported files:**

- NONE

**Home Manager options set by this file:**

- `home.packages` — user profile package list
- `cypher-os.apps.productivity.claude.enable` — defaulted to `true`
- `cypher-os.apps.productivity.obsidian.enable` — defaulted to `true`
- `cypher-os.apps.productivity.penpot.enable` — defaulted to `true`

**nixpkgs packages required:**

- `drawio`, `staruml`, `libreoffice`, `gimp`, `inkscape`, `blender`, `krita`, `kdePackages.kdenlive`, `audacity`, `obs-studio`, `figma-agent`, `vlc`, `spotify`, `clapper`, `discord`, `whatsapp-electron`, `whatsapp-chat-exporter`, `telegram-desktop`

**External flake inputs used:**

- None directly

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.apps.enable`|`bool`|—|Top-level apps kill-switch; read here, declared upstream|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Gates this entire file|
|`cypher-os.apps.productivity.claude.enable`|`bool`|`false`|Set to `lib.mkDefault true` here when group is active|
|`cypher-os.apps.productivity.obsidian.enable`|`bool`|`false`|Set to `lib.mkDefault true` here when group is active|
|`cypher-os.apps.productivity.penpot.enable`|`bool`|`false`|Set to `lib.mkDefault true` here when group is active|

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

---

## Design Notes

- `n8n` migrated out of this file to `modules/devops/n8n.nix` — _it's retained as a commented-out EXCLUDED entry so the list remains a complete record of what was considered and where things went._
- `houdini` is excluded — Planned implementation
- The `lib.mkDefault` pattern here creates an implicit coupling between the group enable and the app-level enables. It works correctly but is acknowledged as an area of planned improvement — _a future session will introduce explicit assertions and a more centralised profile management strategy._

---

## Known Limitations

- The `lib.mkDefault true` assignments for app-level enables inside an `mkIf` that already guards on the parent group enable is a functional but non-ideal pattern. It does not prevent a user from setting `claude.enable = true` while `productivity.enable = false` (_which silently does nothing_). A planned session will address this with assertions and centralised profile management.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Sub-module: Claude|`./claude.nix`|
|Sub-module: Obsidian|`./obsidian.nix`|
|Sub-module: Penpot HM|`./penpot-hm.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/apps/productivity/hm.nix
Context: Home Manager
Created: 2026-06-10
Updated: 2026-06-10
-->
