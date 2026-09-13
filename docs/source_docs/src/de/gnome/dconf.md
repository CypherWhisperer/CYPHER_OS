<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME dconf Settings — `dconf.nix`

> _Declaratively applies all non-extension GNOME dconf keys: interface, keyboard, power, workspaces, peripherals, wallpaper pointers, Nautilus, dock favorite apps, and app-grid folders._

**Module path:** `modules/de/gnome/dconf.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Writes all `dconf.settings` keys that configure the GNOME desktop itself — _interface appearance, keyboard layout and XKB remapping, workspace behaviour, power management, night light, touchpad/mouse, wallpaper URI references, Nautilus preferences, and app-grid folder organisation._
- Re-derives `ctpThemeName` locally (_Option A_) to write the `gtk-theme` dconf key under `org/gnome/desktop/interface` — _the runtime GTK3 theme selection signal, distinct from the HM `gtk` module declaration in `theming.nix`._
- Owns the `org/gnome/shell.favorite-apps` dash list

**Does not:**

- Configure any extension-specific dconf paths (`org/gnome/shell/extensions/*`) — those live in `extensions.nix` alongside the packages that own them.
- Install any packages.
- Manage the `enabled-extensions` UUID list — that is `extensions.nix`.
- Own the `user-theme.name` dconf key — that is `theming.nix` because it consumes `ctpThemeName` from that file's `let` scope.

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

**What is this?** Single-element import list pulling in `options.nix`.

**What does it do?** Makes `cypher-os.de.gnome.enable` resolvable for the kill-switch guard.

**Why is it here?** Sub-module self-containment — _same rationale as all other sub-modules._

```nix
imports = [ ./options.nix ];
```


---

### Block 2 — `org/gnome/desktop/interface`

**What is this?** dconf keys controlling the GNOME interface appearance and runtime defaults.

**What does it do?** Sets: dark colour scheme preference (`color-scheme = "prefer-dark"`), 24h clock, battery percentage display, default fonts for UI/document/monospace, GTK3 theme selection (`gtk-theme = ctpThemeName`), and cursor theme/size. These are read by GNOME Shell and GTK apps at session start and on settings-daemon restart.

**Why is it here?** Interface defaults are a desktop preference concern — they belong in this file alongside all other non-extension dconf settings. The `gtk-theme` key in particular must match `gtk.theme.name` in `theming.nix` exactly; they serve different consumers (dconf-reading apps vs. GTK settings.ini-reading apps) but must agree on the theme name string.

The `icon-theme` key is commented out — icon management is delegated to `catppuccin/nix` globally.

```nix
"org/gnome/desktop/interface" = {
  color-scheme  = "prefer-dark";
  clock-format  = "24h";
  gtk-theme     = ctpThemeName;
  cursor-theme  = "Adwaita";
  cursor-size   = 24;
  # ...
};
```

---

### Block 3 — `org/freedesktop/appearance`

**What is this?** An XDG portal dconf key enforcing dark mode at the portal level.

**What does it do?** Sets `color-scheme` to `1` (dark) as a `uint32` GVariant. XDG portals (used by Flatpak apps and portal-aware native apps) read this key rather than the GNOME-specific `org/gnome/desktop/interface.color-scheme`. Setting both ensures consistent dark mode enforcement across GTK3, GTK4/libadwaita, and portal-mediated apps.

**Why is it here?** Portal settings are a system-wide appearance preference, not extension-specific. `lib.hm.gvariant.mkUint32` is required because the dconf schema type for this key is `u` (unsigned 32-bit integer) — a plain Nix integer would fail GVariant type checking at activation time.

```nix
"org/freedesktop/appearance" = {
  color-scheme = lib.hm.gvariant.mkUint32 1;
};
```

---

### Block 4 — `org/gnome/desktop/input-sources`

**What is this?** dconf keys configuring keyboard layout and XKB modifier remapping.

**What does it do?** Sets the input source to US QWERTY (`('xkb', 'us')` tuple) and applies three XKB options: `ctrl:swapcaps` (physical Caps Lock ↔ Left Ctrl swap), `menu:super` (Menu key → Super), and `altwin:menu_win` (reinforces Menu→Super at XKB level). The `sources` value uses `lib.hm.gvariant.mkTuple` because the schema type is a list of `(ss)` tuples.

**Why is it here?** Keyboard remapping via XKB options in dconf eliminates the need for a `keyd` daemon, `xmodmap` scripts, or systemd user services. The remapping is applied at the GNOME input method level — it works consistently across Wayland and survives session restarts without additional service management.

```nix
"org/gnome/desktop/input-sources" = {
  sources     = [ (lib.hm.gvariant.mkTuple ["xkb" "us"]) ];
  xkb-options = [ "ctrl:swapcaps" "menu:super" "altwin:menu_win" ];
};
```

---

### Block 5 — Window manager keybindings

**What is this?** dconf keys under `org/gnome/desktop/wm/keybindings` mapping keyboard shortcuts to workspace navigation actions.

**What does it do?** Defines Vim-style workspace navigation: `<Control>1-4` for direct workspace jumps, `<Control>h/l` for left/right, `<Control><Alt>Up/Down` for vertical, and the corresponding `<Control><Shift>*` variants for moving windows between workspaces.

**Why is it here?** These bindings were ported from a prior Debian dconf dump and represent a stable personal workflow. Declaring them here ensures they survive HM regenerations — GNOME would otherwise reset to its defaults on any `dconf reset` or fresh session.

```nix
"org/gnome/desktop/wm/keybindings" = {
  switch-to-workspace-left  = [ "<Control>h" ];
  switch-to-workspace-right = [ "<Control>l" ];
  # ...
};
```

---

### Block 6 — Workspace behaviour

**What is this?** Two dconf keys controlling workspace creation and count.

**What does it do?** `org/gnome/mutter.dynamic-workspaces = true` enables GNOME's automatic workspace creation/removal — new workspaces appear when all existing ones are occupied, empty ones are removed. `org/gnome/desktop/wm/preferences.num-workspaces = 11` sets the upper bound, matching the prior Debian configuration.

**Why is it here?** Workspace behaviour is a fundamental desktop preference. Dynamic workspaces interact with the `<Control>1-4` keybindings — if fewer than 4 workspaces exist at a given moment, the numbered shortcuts still work but create workspaces on demand.

```nix
"org/gnome/mutter"                 = { dynamic-workspaces = true; };
"org/gnome/desktop/wm/preferences" = { num-workspaces = 11; };
```

---

### Block 7 — Power management

**What is this?** Three dconf paths controlling idle behaviour, power button action, and sleep timeouts.

**What does it do?** `idle-delay = mkUint32 0` disables automatic screen dimming from inactivity entirely. `idle-dim = false` reinforces this. `power-button-action = "suspend"` maps the physical power button to suspend rather than shutdown. `sleep-inactive-ac-type = "nothing"` prevents sleep on AC power; `sleep-inactive-battery-timeout = 900` suspends after 15 minutes on battery.

**Why is it here?** Power management is a system behaviour preference — no extension dependency. `idle-delay` requires `lib.hm.gvariant.mkUint32` because the schema type is `u`.

```nix
"org/gnome/desktop/session"                  = { idle-delay = lib.hm.gvariant.mkUint32 0; };
"org/gnome/settings-daemon/plugins/power"    = { sleep-inactive-ac-type = "nothing"; ... };
```

---

### Block 8 — Night Light

**What is this?** dconf keys enabling the GNOME night light (blue light filter) on a manual schedule.

**What does it do?** Enables night light (`night-light-enabled = true`) and disables automatic timezone-based scheduling in favour of a manually configured schedule (`night-light-schedule-automatic = false`). The schedule times themselves are not declared here — they default to GNOME's built-in values and are expected to be set via the Settings UI as needed.

**Why is it here?** Night light is a display preference — belongs alongside other interface settings. The schedule is intentionally left to manual configuration because the optimal times are user-habit-dependent and change seasonally.

```nix
"org/gnome/settings-daemon/plugins/color" = {
  night-light-enabled            = true;
  night-light-schedule-automatic = false;
};
```

---

### Block 9 — Touchpad and mouse

**What is this?** dconf keys for touchpad and mouse pointer behaviour.

**What does it do?** Touchpad: enables natural scrolling, two-finger scroll, finger-based click method, and sets speed to `0.455...`. Mouse: disables natural scrolling (conventional direction), sets speed to `0.489...`. Speed values are floating-point and were calibrated from a prior Debian dconf dump.

**Why is it here?** Peripheral preferences are a standard desktop configuration concern. Touchpad natural scroll is enabled while mouse natural scroll is disabled — this is intentional and reflects distinct muscle-memory expectations for each input device.

```nix
"org/gnome/desktop/peripherals/touchpad" = { natural-scroll = true; speed = 0.455...; };
"org/gnome/desktop/peripherals/mouse"    = { natural-scroll = false; speed = 0.489...; };
```

---

### Block 10 — Wallpaper dconf keys

**What is this?** dconf keys under `org/gnome/desktop/background` and `org/gnome/desktop/screensaver` pointing to the wallpaper file.

**What does it do?** Sets the desktop wallpaper and lock screen background to the same image file via `file://` URIs. `picture-options = "zoom"` scales the image to fill the screen. The file at the referenced path is placed by `assets.nix` — these keys are the consumer of that placement guarantee.

**Why is it here?** Wallpaper URI references are non-extension desktop preferences. They are kept here (rather than in `assets.nix`) because they are dconf concerns, not file-placement concerns — `assets.nix` owns the file, `dconf.nix` owns the pointer to it.

**Known issue:** The path is hardcoded to `/home/cypher-whisperer/...`. See Known Limitations.

```nix
"org/gnome/desktop/background"  = { picture-uri = "file:///home/cypher-whisperer/..."; };
"org/gnome/desktop/screensaver" = { picture-uri = "file:///home/cypher-whisperer/..."; };
```

---
### Block 11 — `dconf.settings."org/gnome/shell".favorite-apps`

**What is this?** A dconf key listing `.desktop` file names that populate the GNOME dash/dock.

**What does it do?** GNOME Shell reads this list and displays the corresponding application launchers in the dash in left-to-right order. Entries referencing non-installed applications produce a broken icon; they do not cause an error.

**Why is it here?** The dash favorites list is shell state, and this file owns the `org/gnome/shell` dconf path for the enabled-extensions list. Placing `favorite-apps` in the same path key avoids splitting a single dconf path across two files, which would require careful `lib.mkMerge` handling. Since both keys live under `"org/gnome/shell"`, they are naturally co-located here.

> **NOTE: # To find the .desktop names, simply run the command below that checks places where GNOME looks for and returns a sorted list:

```bash

find /run/current-system/sw/share/applications \
~/.local/share/applications \
~/.nix-profile/share/applications \
/etc/profiles/per-user/$USER/share/applications \
-name "*.desktop" 2>/dev/null | xargs -I{} basename {} | sort
```


```nix
"org/gnome/shell" = {
  favorite-apps = [ "brave-browser.desktop" ... ];
};
```


---
### Block 12 — Nautilus preferences

**What is this?** Three dconf paths configuring the Nautilus file manager.

**What does it do?** Sets the default view to icon view, default icon zoom to small, and the default archive compression format to `tar.xz`.

**Why is it here?** Nautilus is a core GNOME component — its preferences are GNOME desktop configuration, not an extension concern. `tar.xz` is preferred for its compression ratio on a system where disk space and reproducibility matter.

```nix
"org/gnome/nautilus/preferences"  = { default-folder-viewer = "icon-view"; };
"org/gnome/nautilus/icon-view"    = { default-zoom-level = "small"; };
"org/gnome/nautilus/compression"  = { default-compression-format = "tar.xz"; };
```

---

### Block 13 — App grid folders

**What is this?** dconf keys defining named app-grid folders and their app membership.

**What does it do?** Creates two folders in the GNOME app grid — `System` (disk utility, system monitor, network manager, tweaks) and `Utilities` (document viewer, font viewer, image viewer, log viewer) — and populates them with the listed `.desktop` file names. `folder-children` declares the folder names; the per-folder paths define their contents and display names.

**Why is it here?** App grid organisation is a desktop shell preference — non-extension dconf, not extension configuration. Declaring it here keeps the app grid layout under version control and reproducible across reinstalls.

```nix
"org/gnome/desktop/app-folders" = { folder-children = ["System" "Utilities"]; };
"org/gnome/desktop/app-folders/folders/System"    = { apps = [...]; };
"org/gnome/desktop/app-folders/folders/Utilities" = { apps = [...]; };
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares `cypher-os.de.gnome.enable`.

**Home Manager options set by this file:**

- `dconf.settings.*` — all keys documented in the Block Analysis above.

**nixpkgs packages required:**

- None — this file sets dconf keys only; no packages are instantiated.

**External flake inputs used:**

- None.

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

- **`ctpThemeName` Option A duplication:** The four primitive bindings are duplicated from `theming.nix`. If the theme picks change in `theming.nix`, they must be mirrored here — failing to do so causes `gtk-theme` to reference a theme that doesn't match the installed one, resulting in GTK3 apps falling back to Adwaita silently. A future improvement is to promote the picks to `cypher-os.de.gnome.theme.*` options in `options.nix`, eliminating the duplication. This is documented as a future option slot in `options.nix`.
- **`favorite-apps` placement:** This key shares the `"org/gnome/shell"` dconf path with `enabled-extensions` in `extensions.nix`. The NixOS/HM module system merges `dconf.settings` attrsets from multiple modules, so splitting a dconf path across files is legal — _each file contributes keys to the merged attrset for that path._ However, keeping `favorite-apps` in `dconf.nix` rather than `extensions.nix` is deliberate: the dash list is a general shell preference, not an extensions concern. If the two files ever declared the same key under the same path, the last declaration (_by `lib.mkDefault` priority_) would win — _a silent conflict._ This is not currently the case.
- **Speed values as floats:** Touchpad and mouse speed values are stored as `double` in the dconf schema. The precise values (`0.45531914893617031`, `0.4893617021276595`) were carried over from a Debian dconf dump. They can be adjusted freely — _the granularity of the stored value exceeds human perceptual resolution._
- **`idle-delay` and `color-scheme` GVariant types:** Two keys in this file require explicit GVariant type wrappers: `idle-delay` (`mkUint32`) and `org/freedesktop/appearance.color-scheme` (`mkUint32 1`). Omitting the wrapper causes HM to write the key as a plain integer (`i` type), which mismatches the schema's `u` type declaration and results in a type error in dconf at activation time.

---

## Known Limitations

- Wallpaper and screensaver paths are hardcoded to `/home/cypher-whisperer/`. If the username changes, these must be updated manually. The correct fix is to reference `config.home.homeDirectory` from the HM context — _this is deferred pending a module option for the home directory or a direct `config` reference._
- Night light schedule times (`night-light-temperature`, `night-light-schedule-from`, `night-light-schedule-to`) are not declared — _they are managed manually via GNOME Settings._ A future improvement would declare these here for full reproducibility.
- App grid folder membership is declared by `.desktop` file name. If a package is removed, its `.desktop` entry disappears but the folder definition remains — _GNOME will show an empty slot or silently drop the missing entry depending on the Shell version._

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Wallpaper file placed by|`./assets.nix`|
|Extension dconf keys|`./extensions.nix` — all `org/gnome/shell/extensions/*` paths|
|Shell theme dconf key|`./theming.nix` — `org/gnome/shell/extensions/user-theme`|
|`ctpThemeName` source|`./theming.nix` — Option A duplication|
|Counterpart file|`./system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/dconf.nix
Context: Home Manager
Created: 2026-06-09
Updated: 2026-06-09
-->
