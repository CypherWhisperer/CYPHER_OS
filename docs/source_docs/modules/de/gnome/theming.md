<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME Theming — `theming.nix`

> _Applies the Catppuccin GTK theme across all three GTK rendering layers and exposes the shell theme name to dconf._

**Module path:** `modules/de/gnome/theming.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Defines the Catppuccin theme configuration as a `let` block — _accent, variant, size, computed theme name string, and the overridden `catppuccin-gtk` package._ This is the single source of truth for all theme picks.
- Configures the HM `gtk` module for Layer 1 (_GTK3 apps_) and suppresses HM's auto-generation of `gtk-4.0/gtk.css` to avoid conflicting with the explicit libadwaita asset declaration.
- Places the `gtk-4.0/assets/` directory via `xdg.configFile` for Layer 3 (_libadwaita/GTK4 apps_).
- Writes two dconf keys that consume `ctpThemeName`: `org/gnome/desktop/interface.gtk-theme` (_GTK3 runtime theme selection_) and `org/gnome/shell/extensions/user-theme.name` (_GNOME Shell chrome theme via the user-theme extension_).

**Does not:**

- Manage icon themes — _delegated to `catppuccin/nix` for cross-DE consistency._
- Manage cursor themes beyond the fallback Adwaita declaration — _same delegation rationale._
- Own the `enabled-extensions` list or install the `user-themes` extension package — _those live in `extensions.nix`._ This file only writes the `dconf` key that the extension reads.
- Manage wallpaper or avatar — _those are `assets.nix` concerns._

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

**What does it do?** Makes `cypher-os.de.gnome.enable` resolvable in this file's evaluation context.

**Why is it here?** Same rationale as all sub-modules — self-contained option resolution, no parent dependency.

```nix
imports = [ ./options.nix ];
```

---

### Block 2 — Catppuccin `let` bindings

**What is this?** Four `let` bindings: `ctpAccent`, `ctpVariant`, `ctpSize`, `ctpThemeName` (_computed string_), and `ctpGtkPkg` (_overridden nixpkgs derivation_).

**What does it do?** `ctpThemeName` uses `lib.strings.toUpper` / `lib.strings.substring` to title-case each segment and assemble the exact directory name the `catppuccin-gtk` package installs under `/share/themes/`. `ctpGtkPkg` overrides `pkgs.catppuccin-gtk` with the chosen accent, size, variant, and `tweaks = ["normal"]` (_standard window button layout_). Both are referenced by downstream blocks in this file and `ctpThemeName` is re-derived independently in `dconf.nix` using the same four primitive bindings (_Option A cross-module sharing_).

**Why is it here?** Theming is the only concern that needs these bindings for package instantiation (`ctpGtkPkg`). Placing the SSOT here means changing the accent or variant requires editing exactly one file.
```nix
ctpAccent  = "mauve";
ctpVariant = "mocha";
ctpSize    = "standard";
ctpThemeName = "Catppuccin-${...}-Dark"; # title-cased assembly
ctpGtkPkg  = pkgs.catppuccin-gtk.override { ... };
```

---

### Block 3 — `gtk` HM module configuration

**What is this?** The HM `gtk` module attrset, configuring GTK3 theme, cursor, font, and suppressing GTK4 auto-management.

**What does it do?** Writes `~/.config/gtk-3.0/settings.ini` with the Catppuccin theme name and `~/.config/gtk-4.0/settings.ini` with cursor and font settings. GTK3 apps (_Nautilus widget chrome, older GNOME apps_) read `settings.ini` on launch to select the theme from `/share/themes/`.

The `gtk4.extraConfig = {}` declaration prevents the HM `gtk` module from auto-generating `~/.config/gtk-4.0/gtk.css`, which would conflict with the explicit `xdg.configFile` declaration in Block 4._On recent HM unstable, gtk.enable = true with a theme set causes the gtk module to auto-generate ~/.config/gtk-4.0/gtk.css, which conflicts with our explicit home.file declarations that handle libadwaita theming properly. Setting gtk4.extraConfig to empty and not declaring gtk4.theme prevents HM from touching that path._

**Why is it here?** GTK theming is inseparable from the Catppuccin package bindings — _the `theme.package` and `theme.name` fields must reference `ctpGtkPkg` and `ctpThemeName` respectively, both of which are only in scope in this file's `let` block._

The `iconTheme` block is intentionally commented out. Icon and cursor theme management was delegated to `catppuccin/nix` for cross-DE consistency — _the global `catppuccin.enable` flag in the system configuration handles Papirus folder coloring._ Re-enabling icon/cursor management here would create a conflict with that global declaration.

```nix
gtk = {
  enable = true;
  theme   = { name = ctpThemeName; package = ctpGtkPkg; };
  cursorTheme = { name = "Adwaita"; package = pkgs.adwaita-icon-theme; size = 24; };
  font    = { name = "Cantarell"; size = 11; };
  gtk4.extraConfig = {};
};
```

---

### Block 4 — `xdg.configFile."gtk-4.0/assets"`

**What is this?** An `xdg.configFile` entry placing the GTK4 assets directory from the Catppuccin theme package into `~/.config/gtk-4.0/assets/`.

**What does it do?** Symlinks the assets directory (_containing SVG/PNG resources that GTK4 widgets reference at render time_) into the user config path. `recursive = true` tells HM to recurse into the source directory and symlink its contents rather than symlinking the directory node itself. Without this, libadwaita apps render with broken or missing widget decorations even when `gtk.css` is present.

**Why is it here?** The HM `gtk` module auto-generates `gtk.css` and `gtk-dark.css` for GTK4 when a theme is set, but it does not copy the `assets/` directory. This declaration fills that gap. Using `xdg.configFile` rather than `home.file` avoids a path collision with the absolute-path entry the `gtk` module generates internally for `gtk-4.0/gtk.css`.

> _Libadwaita apps (GNOME Settings, Text Editor, Calculator, etc.) deliberately ignore gtk.theme — they only read ~/.config/gtk-4.0/gtk.css at startup. home.file places these symlinks into the profile on every HM switch, so the CSS is always present before any app launches._
>
> _xdg.configFile targets $XDG_CONFIG_HOME (~/.config/) using a separate HM namespace from home.file, avoiding the collision with the absolute-path entry the gtk module generates internally for gtk-4.0/gtk.css._

```nix
xdg.configFile."gtk-4.0/assets" = {
  recursive = true;
  source = "${ctpGtkPkg}/share/themes/${ctpThemeName}/gtk-4.0/assets";
};
```

---

### Block 5 — `dconf.settings` theming keys

**What is this?** A `dconf.settings` attrset containing two keys: `org/gnome/desktop/interface.gtk-theme` and `org/gnome/shell/extensions/user-theme.name`.

**What does it do?** `gtk-theme` instructs running GTK3 applications (_via the GSettings/dconf stack_) which theme to load from `/share/themes/` — _it must match `gtk.theme.name` exactly or apps will silently fall back to Adwaita._ `user-theme.name` is read by the `user-theme` GNOME Shell extension to apply the Catppuccin shell theme (_top bar, overview chrome, notifications_) from the same theme directory.

**Why is it here?** Both keys consume `ctpThemeName` directly, which is only in scope in this file. Placing them here avoids passing the string across module boundaries. The `user-theme` extension is installed and enabled in `extensions.nix`, but the dconf key it reads is a theming concern — the split mirrors the ownership model: extensions.nix owns the extension lifecycle, theming.nix owns what the extension applies.

> _Requires the user-theme extension to be installed and enabled. The catppuccin-gtk package installs a gnome-shell/ subdirectory inside the theme folder, which this extension reads._

```nix
dconf.settings = {
  "org/gnome/shell/extensions/user-theme" = { name = ctpThemeName; };
  "org/gnome/desktop/interface"           = { gtk-theme = ctpThemeName; };
};
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares `cypher-os.de.gnome.enable`.

**Home Manager options set by this file:**

- `gtk.*` — GTK3/4 theme, cursor, font configuration.
- `xdg.configFile."gtk-4.0/assets"` — libadwaita asset directory placement.
- `dconf.settings."org/gnome/desktop/interface".gtk-theme` — GTK3 runtime theme.
- `dconf.settings."org/gnome/shell/extensions/user-theme".name` — Shell chrome theme.

**nixpkgs packages required:**

- `pkgs.catppuccin-gtk` — overridden with accent/variant/size. Provides GTK3 and GTK4 theme CSS and assets.
- `pkgs.adwaita-icon-theme` — cursor theme fallback.

**External flake inputs used:**

- `catppuccin/nix` flake input — manages global icon/cursor theme via `catppuccin.enable`. This file intentionally does _not_ use it directly but defers to it for icon management.

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

- **Three-layer GTK model:** Layer 1 = GTK3 (_`gtk.theme` + dconf `gtk-theme`_), Layer 2 = GNOME Shell chrome (_`user-theme` extension + dconf `user-theme.name`_), Layer 3 = GTK4/libadwaita (_`xdg.configFile` assets + HM-generated `gtk.css`_). All three layers must reference the same `ctpThemeName` string or theming will be inconsistent across app categories.

- **`gtk4.extraConfig = {}`:** This is a suppression declaration, not a configuration. It exists solely to prevent HM from auto-generating `~/.config/gtk-4.0/gtk.css` from the `gtk.theme` value, which would produce a minimal CSS file that conflicts with the full Catppuccin CSS the `xdg.configFile` approach delivers. See the GTK module HM changelog for the version where this auto-generation was introduced.

- **Cursor theme fallback to Adwaita:** Catppuccin cursor (_`pkgs.catppuccin-cursors.mochaDark`_) is available and tested. It is currently disabled in favour of Adwaita because `catppuccin/nix` global cursor management takes precedence on the current system. The commented block in source preserves the full configuration for easy re-enablement.

---

## Known Limitations

- The `ctpThemeName` string computation uses `lib.strings` gymnastics to title-case each segment dynamically. If the upstream `catppuccin-gtk` package ever changes its directory naming convention, the computed string will silently produce a wrong theme name. A rebuild-time assertion checking that the theme directory exists inside `ctpGtkPkg` would catch this, but is not currently implemented.
- GTK4/libadwaita theming via `xdg.configFile` places symlinks, not copies. If a GTK4 app is launched from a context where the Nix store is unavailable (_e.g., certain sandboxed environments_), the symlinks will be dangling. This is a theoretical concern on a standard NixOS setup.
- Icon theme management is fully delegated to `catppuccin/nix` — this file has no fallback if that flake input is removed or the global `catppuccin.enable` is set to `false`.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Extension that reads shell theme|`./extensions.nix` — `user-themes` package + UUID|
|dconf keys duplicating `ctpThemeName`|`./dconf.nix` — Option A re-derivation|
|Counterpart file|`./system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/theming.nix
Context: Home Manager
Created: 2026-06-09
Updated: 2026-06-09
-->
