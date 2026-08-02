<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME Options — `options.nix`

> _Declares the `cypher-os.de.gnome` option namespace — the sole kill-switch surface for the entire GNOME module tree._

**Module path:** `modules/de/gnome/options.nix`
**Evaluation context:** `Both (options declaration)`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Declares all `cypher-os.de.gnome.*` options that the rest of the GNOME module tree reads.
- Provides the `enable` kill-switch that every sub-module (_`hm.nix`, `assets.nix`, `theming.nix`, `extensions.nix`, `dconf.nix`_) gates its `config` block against.
- Reserves commented-out option slots for future sub-options (_`extensions.enable`, `theme.accent`, etc._) to signal the intended growth direction of the namespace.

**Does not:**

- Set any `config` values — _this file is pure option declarations._
- Import any other module — _it has no `imports` list._
- Gate itself with a `lib.mkIf` — _option declarations are unconditional by design; they must exist in the merged option set before any `mkIf` reference can resolve._

---

## Evaluation Context

| Property              | Value                                                                                |
| --------------------- | ------------------------------------------------------------------------------------ |
| Evaluated by          | `both` — _imported by HM sub-modules and visible to NixOS context via `default.nix`_ |
| Options namespace     | `cypher-os.de.gnome`                                                                 |
| Imports `options.nix` | Is `options.nix`                                                                     |
| Kill-switch guard     | None — _option declarations are unconditional_                                       |
| Profile default       | `lib.mkDefault false`; opt-in via profile module                                     |

---

## Block Analysis

---

### Block 1 — `options.cypher-os.de.gnome.enable`

**What is this?** A `lib.mkEnableOption` declaration nested under the `cypher-os.de.gnome` attribute path in the top-level `options` attrset.

**What does it do?** Registers a boolean option at `cypher-os.de.gnome.enable` in the merged NixOS/HM option set. `lib.mkEnableOption` is a convenience wrapper that creates a `bool` option with `default = false`, a standard description string (_"Whether to enable GNOME desktop environment"_), and correct merge semantics. Any module in the evaluation context can now read `config.cypher-os.de.gnome.enable` without a type error.

**Why is it here?** The option declaration must exist in the merged set _before_ any `lib.mkIf config.cypher-os.de.gnome.enable` reference is evaluated. Because NixOS/HM module evaluation is lazy but option resolution is eager, placing the declaration in a dedicated file that every sub-module imports unconditionally guarantees correct ordering. A single declaration file also prevents the accidental dual-declaration error that would occur if two sub-modules each tried to declare the same option.

```nix
options.cypher-os.de.gnome = {
  enable = lib.mkEnableOption "GNOME desktop environment";
};
```

---

### Block 2 — future options slots (commented)

**What is this?** Commented-out `lib.mkOption` and `lib.mkEnableOption` stubs inside the `options.cypher-os.de.gnome` attrset.

**What does it do?** Nothing at evaluation time — they are inert comments. They serve as an intention log: the namespace is designed to grow and these are the next likely additions.

**Why is it here?** Placing future option shapes as comments adjacent to the live declaration makes the intended API surface visible without committing to an implementation. When a sub-option is needed, the slot is already positioned correctly in the namespace — uncomment, fill in type and default, update the consuming sub-module.

```nix
# Future options slot in here:
# extensions.enable = lib.mkEnableOption "GNOME Shell extensions";
# theme.accent = lib.mkOption { type = lib.types.str; default = "mauve"; ... };
```

---

## Dependencies

**Imported files:**

- None.

**NixOS options set by this file:**

- None — this file only _declares_ options; it does not set `config.*` values.

**Home Manager options set by this file:**

- None — same reasoning as above.

**nixpkgs packages required:**

- None.

**External flake inputs used:**

- None.

---

## Option Surface

This file _is_ the option surface for the GNOME module tree. Every option declared here is consumed (read via `config.cypher-os.de.gnome.*`) by the sub-modules that import this file.

|Option|Type|Default|Declared by|Read by|
|---|---|---|---|---|
|`cypher-os.de.gnome.enable`|`bool`|`false`|`lib.mkEnableOption`|`hm.nix`, `assets.nix`, `theming.nix`, `extensions.nix`, `dconf.nix`, `system.nix`|

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

- `lib.mkEnableOption` is preferred over a raw `lib.mkOption { type = lib.types.bool; default = false; }` because it generates a standard description automatically and signals intent — _this is a feature gate, not a data option._
- The file has no `imports` list and no `config` block. This is intentional: options declaration files should be pure. Mixing `config` into an options file creates an implicit activation dependency that is hard to reason about and breaks the ability to import the file purely for its option declarations.
- This file is imported by every sub-module individually rather than relying on a parent module to import it once. This makes each sub-module self-contained and evaluable in isolation — _important for debugging and for future portability of individual sub-modules._
- The `cypher-os.de.gnome` namespace sits under `de` (_desktop environment_), which sits under `cypher-os`. The `de` tier exists to group future DE modules (_`hyprland`, `plasma`_) under a common parent without polluting the top-level `cypher-os` namespace. This mirrors the directory structure: `modules/de/gnome/`.

---

## Known Limitations

- The option namespace is currently flat — `cypher-os.de.gnome.enable` is the only live option. As the module grows (_theme accent, extension toggles, per-feature enables_), this file will need to expand. The commented future slots are a reminder, not a guarantee.
- There is no `cypher-os.de.gnome.package` option to select the GNOME Shell version. GNOME Shell version is controlled entirely by the `nixpkgs` input in `flake.nix` — intentionally, since mixing nixpkgs revisions for a DE is complex and rarely needed.

---

## Related

|Type|Reference|
|---|---|
|Consumed by (HM)|`./hm.nix`, `./assets.nix`, `./theming.nix`, `./extensions.nix`, `./dconf.nix`|
|Consumed by (system)|`./system.nix`|
|Module router|`./default.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/options.nix
Context: Both
Created: 2026-06-09
Updated: 2026-06-09
-->
