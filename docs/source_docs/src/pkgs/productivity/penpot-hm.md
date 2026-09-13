<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Penpot HM — `penpot-hm.nix`

> _Home Manager activation layer for Penpot Desktop: installs the desktop client and holds the stubs for future Wayland and XDG config wiring._

**Module path:** `modules/apps/productivity/penpot-hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-10`

---

## Responsibility

**Does:**

- Installs `pkgs.penpot-desktop` into the user profile when both the productivity group and Penpot are enabled

**Does not:**

- Pre-seed the Penpot Desktop config file (`~/.config/Penpot/`) — _this is a documented stub; see Design Notes_
- Set any Wayland or WebKit rendering environment variables — _currently not required; see Design Notes_
- Manage the self-hosted Penpot backend instance — _that lives in a separate Docker Compose project with its own repository (cypher-penpot)_
- Declare any `cypher-os.*` options — _those live in `options.nix`_

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity`|
|Imports `options.nix`|No — `options.nix` is imported by `default.nix`|
|Kill-switch guard|`lib.mkIf (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.penpot.enable)`|
|Profile default|`lib.mkDefault true` set in `modules/apps/productivity/hm.nix`|

---

## Block Analysis

---

### Block 1 — Kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset, conditioned on both `productivity.enable` and `penpot.enable` being `true`.

**What does it do?** When either condition is `false`, the block evaluates to `{}` — nothing is installed and no config is written. When both are `true`, the guarded config is passed to the HM evaluator.

**Why is it here?** Standard CypherOS two-level guard. Penpot Desktop can be disabled independently of the rest of the productivity group — useful when working on a machine or lens where the local Penpot instance is not running and the desktop client is irrelevant.

```nix
config =
  lib.mkIf
    (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.penpot.enable)
    { ... };
```

---

### Block 2 — `home.packages`

**What is this?** A `home.packages` assignment using `with pkgs;` containing a single entry: `penpot-desktop`.

**What does it do?** Installs the Penpot Desktop Electron client into the user's Home Manager profile. `penpot-desktop` is available in nixpkgs. The installed client points to the self-hosted instance at `https://design.penpot.local` — the local DNS resolution and CA trust that make that URL work are handled separately in `penpot-system.nix`.

**Why is it here?** Penpot Desktop is a user-space application that belongs in the HM profile, not as a system package. Separating the client install (here) from the system-level prerequisites (DNS entry, CA trust in `penpot-system.nix`) keeps each concern in its correct evaluation context.

```nix
home.packages = with pkgs; [
  penpot-desktop
];
```

---

### Block 3 — Stubs (commented out)

**What is this?** Two commented-out blocks retained in the source as explicit markers of future work:

1. A note about optionally writing `~/.config/Penpot/` via `home.file` to pre-seed the local instance URL declaratively, with a caveat that Electron may overwrite the file at runtime.
2. A note about future environment variable handling for Wayland/X11, WebKit rendering flags, or GNOME integration.

**What does it do?** Nothing at present — both are comments only.

**Why is it here?** Penpot Desktop currently runs cleanly on the GNOME Wayland lens without any additional environment variable intervention. The stubs serve as explicit reminders of two surfaces that may need attention as the DE lens portfolio expands (Plasma target) or if Penpot Desktop's upstream rendering behaviour changes. Keeping them visible in the source means the next person to touch this file is not starting from a blank slate — the known unknowns are already named.

The `home.file` approach for pre-seeding the instance URL carries a specific fragility: Electron apps often overwrite their config files on launch with their own serialised state, which would silently clobber the HM-managed symlink. If instance URL pre-seeding is ever implemented, the right approach is to verify whether Penpot Desktop respects an existing config file or overwrites it, and decide accordingly whether `home.file` (symlink, read-only from Obsidian's perspective) or a one-time setup script is more appropriate.

```nix
# OPTIONAL: write a ~/.config/Penpot/ config file via home.file to pre-seed
# my local instance URL declaratively
# (possible but slightly fragile since Electron may overwrite it)

# Handle any environment variables needed for
# Wayland/X11, WebKit rendering flags, or GNOME integration
```

---

## Dependencies

**Imported files:**

- None directly

**Home Manager options set by this file:**

- `home.packages` — installs `pkgs.penpot-desktop`

**nixpkgs packages required:**

- `pkgs.penpot-desktop` — available in nixpkgs

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group kill-switch; must be `true` for this file to activate|
|`cypher-os.apps.productivity.penpot.enable`|`bool`|`false`|App kill-switch; `lib.mkDefault true` set by `hm.nix`|

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

- The system-level prerequisites for the local Penpot instance — _`/etc/hosts` entry for `design.penpot.local` and Caddy CA trust_ — are intentionally not here. They are NixOS system concerns and live in `penpot-system.nix`. This file is purely the user-space side.
- Penpot Desktop runs cleanly on the current GNOME Wayland lens with no additional flags. The environment variable stub is retained as a forward-looking marker, not as evidence of a problem.
- Instance URL pre-seeding via `home.file` is explicitly deferred, not excluded. The concern is Electron's runtime config file behaviour — this needs verification before implementation. See Block 3 for the full reasoning.

---

## Known Limitations

- The local Penpot instance URL (`https://design.penpot.local`) is not pre-seeded declaratively. On a fresh activation, the user must manually enter the instance URL in Penpot Desktop's settings at first launch.
- No Wayland rendering flags are set. This is not currently a problem on the GNOME lens, but may require attention when porting to the Plasma lens.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Group HM defaults|`./hm.nix`|
|System counterpart|`./penpot-system.nix`|
|ADR|_None in CypherOS — see Penpot project ADRs_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/apps/productivity/penpot-hm.nix
Context: Home Manager
Created: 2026-06-10
Updated: 2026-06-10
-->
