<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME Assets — `assets.nix`

> _Places wallpaper and avatar image files into the user profile before any GNOME component reads dconf._

**Module path:** `modules/de/gnome/assets.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Declares `home.file` entries for the desktop wallpaper and user avatar, ensuring both files exist on disk at their dconf-referenced paths before GDM or the GNOME session starts.
- Resolves asset paths hermetically relative to the module's position in the Nix store, so assets are always bundled with the configuration — _no runtime path assumptions._

**Does not:**

- Declare the dconf keys that _point_ to the wallpaper path — _those live in `dconf.nix` under `org/gnome/desktop/background` and `org/gnome/desktop/screensaver`._
- Manage the system-level avatar path (`/var/lib/AccountsService/icons/<username>`) — _that is a NixOS system concern handled in `configuration.nix`._
- Own any logic, packages, or settings beyond static file placement.

---

## Evaluation Context

| Property              | Value                                                           |
| --------------------- | --------------------------------------------------------------- |
| Evaluated by          | `homeManagerModules`                                            |
| Options namespace     | `cypher-os.de.gnome`                                            |
| Imports `options.nix` | Yes — _required for the `lib.mkIf` kill-switch guard_           |
| Kill-switch guard     | `lib.mkIf config.cypher-os.de.gnome.enable`                     |
| Profile default       | Inherits from `cypher-os.de.gnome.enable` set in profile module |

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A single-element list passed to the module's top-level `imports` attribute.

**What does it do?** Pulls `options.nix` into this module's evaluation context, making the `cypher-os.de.gnome.enable` option visible so the `lib.mkIf` guard on the `config` block can reference it without an undefined-option error.

**Why is it here?** Each sub-module in the GNOME module tree imports `options.nix` independently. This is intentional — _sub-modules are self-contained and do not rely on a parent module having already imported the options._ The cost is a repeated import declaration; the benefit is that any sub-module can be evaluated or tested in isolation.

```nix
imports = [ ./options.nix ];
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Makes every declaration inside the `config` block conditional on `cypher-os.de.gnome.enable` evaluating to `true`. When the option is `false`, Nix evaluates this block to an empty attrset and contributes nothing to the merged system configuration.

**Why is it here?** All sub-modules in the GNOME tree guard their own `config` block with the same condition. The NixOS module system merges `config` attrsets from all imported modules after evaluation — having each sub-module guard itself produces the same runtime result as one giant `mkIf` in a monolithic file, with the added benefit that each file is independently legible.

```nix
config = lib.mkIf config.cypher-os.de.gnome.enable { ... };
```

---

### Block 3 — `home.file` wallpaper declaration

**What is this?** A `home.file` attribute set entry that places a JPEG file into the user's home directory at a well-known path.

**What does it do?** On every `nixos-rebuild switch`, Home Manager symlinks (or copies) the file from the Nix store path into `~/.local/share/backgrounds/default-gnome-bg.jpg`. The file is guaranteed to exist at that path before the GNOME session starts — solving the first-boot blank/black wallpaper problem that occurs when dconf is written before the backing file exists.

**Why is it here?** The dconf keys in `dconf.nix` reference this exact path as a `file://` URI. If the file doesn't exist when GNOME reads dconf on session start, it silently falls back to a solid colour. Declaring the file in Home Manager ensures it is placed atomically with the rest of the configuration on every activation.

```nix
home.file.".local/share/backgrounds/default-gnome-bg.jpg" = {
  source = ../assets/images/default-gnome-bg.jpg;
};
```

---

### Block 4 — `home.file` avatar declaration

**What is this?** A `home.file` entry targeting `~/.face` — _the conventional GNOME user avatar path._

**What does it do?** Places the avatar JPEG at `~/.face`. GNOME Shell reads this path to display the user tile on the lock screen and in the user menu. No explicit format conversion is needed — _GNOME accepts JPEG at this path._

**Why is it here?** `~/.face` is a well-known path read by GNOME Shell at session start. Without a declarative placement, the avatar reverts to the default silhouette on every fresh Home Manager generation that hasn't been manually seeded. Declaring it here keeps the avatar under version control alongside the rest of the configuration.

```nix
home.file.".face" = {
  source = ../assets/images/default-gnome-avatar.jpg;
};
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares `cypher-os.de.gnome.enable`; required for the kill-switch guard to resolve at eval time.

**Home Manager options set by this file:**

- `home.file.".local/share/backgrounds/default-gnome-bg.jpg"` — wallpaper file placement.
- `home.file.".face"` — user avatar file placement.

**nixpkgs packages required:**

- None — this file performs only static file placement; no derivations are instantiated.

**External flake inputs used:**

- None. Asset files are resolved via relative paths from the module's position in the Nix store (`../assets/images/`), making them hermetic with respect to the flake.

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.de.gnome.enable`|`bool`|`false`|Top-level kill-switch; gates all declarations in this file|

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

- Asset paths use `../assets/images/` — _a relative path from `modules/de/gnome/` up one level to `modules/de/assets/images/`._ This is resolved by Nix at eval time and copied into the store, making the configuration fully hermetic: the assets travel with the flake.
- `home.file` uses symlinks by default. If the source path is a store path (_as it is here_), the symlink points into `/nix/store/...` — immutable and correct. No `force = true` or `copy` override is needed.
- The system-level avatar path (_`/var/lib/AccountsService/icons/cypher-whisperer`_) is intentionally out of scope for this file. AccountsService requires a system-level declaration in `configuration.nix` because that path is outside `$HOME` and is written by a system daemon. See `system.nix` or `configuration.nix` for that concern.

---

## Known Limitations

- The wallpaper path is hardcoded to `/home/cypher-whisperer/...` in `dconf.nix` — this is a separate file and is not derived from `home.homeDirectory`. If the username changes, `dconf.nix` must be updated manually. A future improvement would be to read `config.home.homeDirectory` in `dconf.nix` to make the path dynamic.
- Only one wallpaper and one avatar are supported. Multiple profiles or per-workspace wallpapers would require additional `home.file` entries and corresponding dconf keys.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|dconf wallpaper keys|`./dconf.nix` — `org/gnome/desktop/background` and `org/gnome/desktop/screensaver`|
|Counterpart file|`./system.nix` — system-level avatar via AccountsService|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/assets.nix
Context: Home Manager
Created: 2026-06-09
Updated: 2026-06-09
-->
