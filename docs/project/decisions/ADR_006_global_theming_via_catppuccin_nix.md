# ADR-006: Global Theming via catppuccin/nix

**Date:** 2026-06-06
**Status:** Accepted
**Deciders:** CypherWhisperer
**Related:**
- [ADR-002 — GNOME Module Isolation](ADR_002_gnome_module_isolation.md) _(established the `gnome/hm.nix` structure this ADR partially refactors)_
- [INC_2026_06_06_001](../../development/incidents/INC_2026_06_06_001.md) _(session during which this decision was made)_

---

## Context

CypherOS accumulated catppuccin theme configuration organically — each app module that needed theming got its own hand-rolled implementation. By the time this ADR was written, catppuccin colors were declared in at least four places:

- `modules/apps/terminal/ghostty.nix` — full `themes.catppuccin-mocha` palette block
- `modules/apps/dev/git.nix` — `programs.delta.options.syntax-theme` and `features` string
- `modules/de/gnome/hm.nix` — `gtk.iconTheme` with `catppuccin-papirus-folders.override`
- `modules/apps/editor/vscode.nix` — `catppuccin.vscode.profiles.default` block

The `catppuccin/nix` flake was already a declared input and its HM module was already imported in both evaluation paths in `flake.nix`. The module was being used for VSCode theme compilation (the specific use case that motivated importing it — bypassing the read-only store problem). However, the global enable switch (`catppuccin.enable = true`) was never set, meaning the module's `autoEnable` cascade never activated, and every other app remained on its hand-rolled config.

A routine `nix flake update` on 2026-06-06 advanced the `catppuccin` input rev and surfaced the missing global switch as a VSCode regression — the VSCode extension was no longer being injected because the module was effectively inert. Diagnosing this led to the decision to activate the global switch and migrate the hand-rolled configs to module ownership.

---

## Decision

Set `catppuccin.enable = true`, `catppuccin.flavor = "mocha"`, and `catppuccin.accent = "mauve"` globally in the desktop profile. Remove hand-rolled catppuccin theme declarations from individual app modules for any app the catppuccin/nix module manages, letting `autoEnable` cascade handle them.

---

## Reasoning

The hand-rolled approach had three compounding problems:

**1. Redundancy.** The catppuccin/nix module was already imported and already owned VSCode theming. Every hand-rolled block was duplicating work the module does better — including pulling upstream-maintained theme files rather than hardcoding palette values.

**2. Conflict surface.** Once `catppuccin.enable = true` was set, every hand-rolled block for a supported app became a conflicting definition. The module injects its own values; Nix refuses to merge them with manual values on unique options. Each conflict required either removing the manual block or escalating with `lib.mkForce`. The latter is appropriate only when you genuinely want to override module behaviour — not when you just want the same outcome.

**3. Maintenance overhead.** Palette values hardcoded in module files are a drift risk. The catppuccin/nix module sources theme files from the official catppuccin repos; hand-rolled palette blocks do not track upstream changes.

The migration pattern is clean: remove the manual declaration, the module owns the outcome. For cases where the module's output is correct but conflicts with a legitimate customisation (delta `features` string), `lib.mkForce` is the right tool.

---

## What catppuccin/nix Manages (as of 2026-06-06)

Understanding module scope is essential — not every app is managed, and the gtk module's scope is narrower than expected.

| App          | Managed by catppuccin/nix | Notes                                                                                       |
| ------------ | ------------------------- | ------------------------------------------------------------------------------------------- |
| VSCode       | ✅ Yes                    | Pre-compiles theme at build time; necessary for read-only store compatibility               |
| Ghostty      | ✅ Yes                    | Injects theme file via `xdg.configFile`                                                     |
| Delta        | ✅ Yes                    | Sets `features = "catppuccin-mocha"` in `programs.delta.options`                           |
| GTK icons    | ✅ Yes                    | Sets `gtk.iconTheme` to `catppuccin-papirus-folders` override                              |
| GTK theme    | ❌ No                     | Upstream `catppuccin-gtk` was archived; module dropped GTK theme management entirely       |
| GTK cursors  | ❌ No                     | Not managed by the HM gtk module                                                            |
| GNOME Shell  | ❌ No                     | Shell theme (user-theme extension) remains in `gnome/hm.nix` dconf settings               |
| Libadwaita   | ❌ No                     | GTK4 CSS assets remain in `gnome/hm.nix` via `xdg.configFile."gtk-4.0/assets"`            |

**GTK theming remains hand-rolled in `gnome/hm.nix`.** The `catppuccin-gtk` upstream repository was archived due to breakages. The catppuccin/nix gtk module now manages only the Papirus icon set. The existing `catppuccin-gtk.override` + libadwaita CSS approach in `gnome/hm.nix` is retained as-is and remains the correct path for GTK3 and libadwaita theming.

---

## Migration Changes Applied

### `modules/apps/terminal/ghostty.nix`
Removed `programs.ghostty.themes.catppuccin-mocha` block entirely. `settings.theme = "catppuccin-mocha"` retained — Ghostty still needs to know which theme to apply; the catppuccin/nix module provides the theme file, the settings key selects it.

### `modules/apps/dev/git.nix`
Removed `programs.delta.options.syntax-theme = "Catppuccin-mocha"`. Resolved `features` conflict with `lib.mkForce "catppuccin-mocha decorations"` — this preserves both the catppuccin-mocha color definitions and the custom `decorations` feature block.

### `modules/de/gnome/hm.nix`
Removed `gtk.iconTheme` block (name and package). Removed matching `icon-theme` dconf key from `org/gnome/desktop/interface`. The catppuccin/nix gtk module now owns icon theming end-to-end.

### Desktop profile (new additions)
```nix
catppuccin.enable = true;
catppuccin.flavor = "mocha";
catppuccin.accent = "mauve";
```

---

## Alternatives Considered

### Keep hand-rolled config, disable catppuccin/nix autoEnable per-app

Set `catppuccin.<app>.enable = false` for every managed app and continue managing themes manually. This avoids conflicts but throws away the primary value of the module — upstream-maintained theme files and zero-maintenance updates. It also doesn't resolve the VSCode regression that triggered this investigation.

### Remove catppuccin/nix from inputs entirely

Revert to managing VSCode theming via the nixpkgs `catppuccin-vsc` extension. This was the original motivation for importing catppuccin/nix in the first place — the nixpkgs extension writes compiled theme JSON to its own directory at activation, which fails in the read-only Nix store. Removing catppuccin/nix reintroduces that problem.

---

## Trade-offs

**Gains:**
- Single source of truth for flavor and accent — one change propagates to all managed apps
- Upstream-maintained theme files; no hardcoded palette values to drift
- Eliminates the entire class of "manual theme block conflicts with module injection" errors for managed apps
- VSCode theming regression resolved and protected against future similar regressions

**Costs / Risks:**
- `autoEnable` means adding a new app that catppuccin/nix supports will automatically get themed, which may surface conflicts if that app already has manual catppuccin config. **Convention going forward:** when adding a new app module, check `nix.catppuccin.com/options/main/home/` first — if the app is listed, do not add manual catppuccin config; rely on the module.
- GTK theming is now in a split state: icons managed by catppuccin/nix, everything else hand-rolled. This is not ideal architecturally but reflects the current upstream reality. Revisit if catppuccin/nix restores GTK theme management in a future release.
- The LibreOffice GTK breakage (white background, low-contrast icons under `catppuccin-gtk`) is pre-existing and unresolved. This ADR does not address it.

---

## Consequences

**Convention established:** For any app added to CypherOS going forward, check catppuccin/nix support before writing manual theme config. If the app is supported, rely on `autoEnable`. If customisation beyond flavor/accent is needed for a specific app, use the `catppuccin.<app>.*` options rather than direct `programs.<app>` overrides where possible.

**`lib.mkForce` usage pattern documented:** When a legitimate customisation conflicts with a catppuccin/nix module injection on the same option (as with delta's `features` string), `lib.mkForce` is the correct resolution — it wins the priority contest while preserving both values in the final output where the option type permits it (e.g. space-separated strings). This is distinct from using `lib.mkForce` to wholesale override module behaviour, which should be treated as a last resort.
