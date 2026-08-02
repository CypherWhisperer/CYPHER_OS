<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME System Configuration — `system.nix`

> _Activates the GNOME desktop manager at the NixOS system level and surgically excludes unwanted default GNOME applications._

**Module path:** `modules/de/gnome/system.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Enables `services.desktopManager.gnome.enable`, which pulls in GNOME Shell, gnome-session, gnome-control-center, Nautilus, and the core GNOME session infrastructure at the system level.
- Declares `environment.gnome.excludePackages` to remove the default GNOME application set that `desktopManager.gnome.enable` installs automatically, producing a minimal GNOME installation.
- Guards both declarations behind a compound kill-switch requiring both `cypher-os.profile.desktop.enable` and `cypher-os.de.gnome.enable` to be `true`.

**Does not:**

- Manage any Home Manager configuration — _that is the `hm.nix` sub-module tree._
- Configure GDM (the display manager) — _that is `cypher-os.dm.gdm.enable`, managed in `modules/dm/`._
- Install user-facing applications beyond the GNOME session infrastructure — _those are Home Manager concerns._
- Declare any options — _those live in `options.nix`._

---

## Evaluation Context

| Property              | Value                                                                                                                                                            |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                                                                                                                   |
| Options namespace     | `cypher-os.de.gnome` + `cypher-os.profile.desktop`                                                                                                               |
| Imports `options.nix` | No — _`options.nix` declares only `cypher-os.de.gnome.*`; `cypher-os.profile.desktop.enable` is declared elsewhere and visible via the merged system option set_ |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.profile.desktop.enable && config.cypher-os.de.gnome.enable)`                                                                         |
| Profile default       | Both guards must be `true`; set in `modules/profile/system.nix`                                                                                                  |

---

## Block Analysis

---

### Block 1 — compound kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` block with a two-condition boolean AND.

**What does it do?** Gates all system-level GNOME declarations on two independent conditions: the desktop profile must be active (`cypher-os.profile.desktop.enable`) and the GNOME DE must be selected (`cypher-os.de.gnome.enable`). Both must be `true` for any of this file's `config` to take effect.

**Why is it here?** The desktop profile guard prevents GNOME system services from being activated on non-desktop system lenses (server, minimal, VM configurations) even if `cypher-os.de.gnome.enable` is accidentally set to `true` in a shared profile. The dual guard is the NixOS expression of "this is a desktop-class machine and specifically a GNOME machine." Other DE modules (`hyprland`, `plasma`) will carry the same `profile.desktop.enable` guard with their own `de.*` condition.

```nix
config = lib.mkIf (config.cypher-os.profile.desktop.enable && config.cypher-os.de.gnome.enable) { ... };
```

---

### Block 2 — `services.desktopManager.gnome.enable`

**What is this?** A NixOS service option that activates the full GNOME session stack at the system level.

**What does it do?** Setting this to `true` causes NixOS to install and configure: GNOME Shell, gnome-session, gnome-control-center, Nautilus, the GNOME settings daemon, gnome-keyring, and the broader GNOME session infrastructure. It also registers the GNOME Wayland session `.desktop` entry that GDM presents as a login option. This is the system-level prerequisite for any Home Manager GNOME configuration to function — without it, GNOME Shell is not on the system and the session cannot start.

**Why is it here?** System service activation belongs in the NixOS evaluation context, not in Home Manager. `hm.nix` and its sub-modules configure the GNOME session for a specific user; `system.nix` makes the session available at all. The split mirrors the NixOS/HM evaluation context separation that is fundamental to CypherOS's module architecture.

```nix
services.desktopManager.gnome.enable = true;
```

---

### Block 3 — `environment.gnome.excludePackages`

**What is this?** A NixOS option accepting a list of package derivations to remove from the default GNOME application set.

**What does it do?** `services.desktopManager.gnome.enable` installs a curated set of GNOME applications system-wide (GNOME Tour, Totem, Maps, Weather, Contacts, Music, Epiphany, Geary, Calendar, and others). `excludePackages` surgically removes entries from that list before the system closure is built. The result is a minimal GNOME installation — only the session infrastructure and explicitly Home Manager–installed applications are present.

**Why is it here?** Bloatware exclusion is a system-level concern because `desktopManager.gnome.enable` installs at the system level. Home Manager cannot remove system packages — the exclusion must happen in the NixOS evaluation context where the package set is being assembled. Each excluded package carries an inline comment explaining the reason, creating an auditable record of intentional omissions.

Excluded applications and rationale:

- `gnome-tour` — first-run wizard, not useful on a declarative system.
- `yelp` — GNOME help browser; documentation accessed via other means.
- `totem` — video player; replaced by Clapper (installed via HM).
- `gnome-maps`, `gnome-weather`, `gnome-contacts`, `gnome-music` — single-purpose GNOME apps not part of the active workflow.
- `epiphany` — GNOME Web browser; replaced by Brave/Firefox (installed via HM).
- `geary` — GNOME mail client; replaced by Proton Mail (web/app via HM).
- `gnome-calendar` — excluded; calendar needs handled elsewhere.
- `simple-scan` — scanner app; no scanner in current hardware setup.
- `gnome-clocks` — excluded by preference.

`gnome-characters` is commented as "borderline useful" — a DEFERRED exclusion pending a firm decision.

```nix
environment.gnome.excludePackages = with pkgs; [
  gnome-tour
  yelp
  totem
  # ...
];
```

---

## Dependencies

**Imported files:**

- None — `system.nix` is imported by `default.nix` and relies on the merged NixOS option set for `cypher-os.profile.desktop.enable` and `cypher-os.de.gnome.enable`.

**NixOS options set by this file:**

- `services.desktopManager.gnome.enable` — activates the GNOME session stack.
- `environment.gnome.excludePackages` — removes specified packages from the default GNOME application set.

**Home Manager options set by this file:**

- None — this file is evaluated in the NixOS context only.

**nixpkgs packages required:**

- `pkgs.gnome-tour`, `pkgs.yelp`, `pkgs.totem`, `pkgs.gnome-maps`, `pkgs.gnome-weather`, `pkgs.gnome-contacts`, `pkgs.gnome-music`, `pkgs.epiphany`, `pkgs.geary`, `pkgs.gnome-calendar`, `pkgs.simple-scan`, `pkgs.gnome-clocks` — referenced in `excludePackages`. These packages must exist in the nixpkgs revision pinned by the flake for the list to evaluate without error.

**External flake inputs used:**

- None.

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.profile.desktop.enable`|`bool`|`false`|First guard — must be `true` for any system GNOME config to activate|
|`cypher-os.de.gnome.enable`|`bool`|`false`|Second guard — must be `true` for any system GNOME config to activate|

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

- **Compound guard design:** Using `&&` in a single `lib.mkIf` rather than nested `mkIf` blocks is a stylistic preference — both produce identical evaluated output. The single-expression form is more readable for a two-condition guard. If a third condition were needed, nested `mkIf` or `lib.mkIf (a && b && c)` would both work; the latter remains readable up to approximately three conditions.
- **`desktopManager.gnome` vs `services.xserver.desktopManager.gnome`:** On NixOS 24.05+, the canonical path is `services.desktopManager.gnome.enable`. The older `services.xserver.desktopManager.gnome.enable` path still works as an alias but is deprecated. The canonical path is used here.
- **Exclusion list maintenance:** When nixpkgs updates GNOME, the default application set may change — new apps may be added that are not in the exclusion list, and old apps may be removed making their exclusion entries stale (stale entries produce evaluation errors). The exclusion list should be audited after every nixpkgs GNOME bump. A rebuild error referencing an unknown package in `excludePackages` is the signal that an entry has become stale.
- **Separation from GDM:** `services.desktopManager.gnome.enable` does not configure GDM. GDM is managed separately via `cypher-os.dm.gdm.enable` in `modules/dm/`. The separation exists because GDM is display-manager infrastructure (_it runs before any user session_) while `desktopManager.gnome` is session infrastructure. They are independently toggleable — _it is valid to use GNOME with SDDM or LightDM if desired._

---

## Known Limitations

- The exclusion list must be manually audited after nixpkgs GNOME version bumps. There is no automated check that excluded packages still exist in nixpkgs — _a stale entry causes an evaluation error at build time._
- `gnome-characters` is in an undecided state (_commented in source_). It should be given an explicit decision (_EXCLUDED with reason, or removed from the comment_) on next review.
- `simple-scan` exclusion note says "keep if thou have a scanner" — this is hardware-dependent. If a scanner is added to the setup, this entry must be removed from `excludePackages` and the application re-added via `home.packages` if desired.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix` (`cypher-os.de.gnome.enable`)|
|HM counterpart|`./hm.nix` and sub-modules|
|GDM configuration|`modules/dm/` — `cypher-os.dm.gdm.enable`|
|Module router|`./default.nix` — imports this file|
|Profile guards set in|`modules/profile/system.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/system.nix
Context: NixOS system
Created: 2026-06-09
Updated: 2026-06-09
-->
