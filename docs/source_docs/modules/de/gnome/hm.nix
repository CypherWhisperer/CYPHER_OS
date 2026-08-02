<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME Home Manager Entry Point — `hm.nix`

> _Composes the GNOME Home Manager sub-modules and owns the XDG profile launcher script — the sole session entry point for the GNOME DE._

**Module path:** `modules/de/gnome/hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Acts as the composition root for all GNOME Home Manager sub-modules: imports `extensions.nix`, `assets.nix`, `theming.nix`, and `dconf.nix`.
- Owns the XDG profile launcher script (`~/.local/bin/launch-gnome`) — _the `home.file` declaration that places the session entry-point script into the user profile._
- Retains the `UNFREE PACKAGES` comment block as a scoping note (_the actual `allowUnfree` declaration lives in `configuration.nix`_).

**Does not:**

- Contain any theming, extension, dconf, or asset logic — all of that is delegated to the sub-modules.
- Declare options — _those live in `options.nix`, which is imported by each sub-module individually._
- Import `options.nix` directly — _the sub-modules handle their own option imports; `hm.nix` does not need to re-import it._

---

## Evaluation Context

| Property              | Value                                                           |
| --------------------- | --------------------------------------------------------------- |
| Evaluated by          | `homeManagerModules`                                            |
| Options namespace     | `cypher-os.de.gnome`                                            |
| Imports `options.nix` | No — _each sub-module imports it independently_                 |
| Kill-switch guard     | `lib.mkIf config.cypher-os.de.gnome.enable`                     |
| Profile default       | Inherits from `cypher-os.de.gnome.enable` set in profile module |

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A four-element import list referencing the GNOME HM sub-modules.

**What does it do?** Pulls all four sub-modules into the HM evaluation context. The NixOS/HM module system merges the `config` attrsets from all imported modules — the result is identical to having all sub-module content in a single file, but with each concern isolated in its own source file.

**Why is it here?** `hm.nix` is the file that `default.nix` imports. Making it a thin composition root means `default.nix` has a single stable import target, and new sub-modules are added by appending to this list — no changes to `default.nix` required.

`options.nix` is intentionally absent from this list. Each sub-module imports `options.nix` itself, which is sufficient for the option to be present in the merged evaluation context. Adding it here would be redundant.

```nix
imports = [
  ./extensions.nix
  ./assets.nix
  ./theming.nix
  ./dconf.nix
];
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the `config` block containing the launcher script.

**What does it do?** Gates the launcher script declaration on `cypher-os.de.gnome.enable`. When the option is `false`, this file contributes nothing to the merged configuration beyond its imports (which are unconditional).

**Why is it here?** The launcher script is a GNOME-specific resource — it should not be placed into the user profile if the GNOME DE is disabled. The guard here mirrors the pattern used in all sub-modules.

```nix
config = lib.mkIf config.cypher-os.de.gnome.enable { ... };
```

---

### Block 3 — `UNFREE PACKAGES` comment

**What is this?** A commented-out `nixpkgs.config.allowUnfree = true` declaration with an explanatory note.

**What does it do?** Nothing at evaluation time — the comment is inert. It documents the decision to scope unfree allowance to `configuration.nix` rather than the HM config.

**Why is it here?** The comment preserves the reasoning in context: unfree packages (Spotify, Obsidian, etc.) are installed by GNOME-specific Home Manager modules, so it's natural to wonder whether `allowUnfree` should live here. The comment explains why it doesn't — the system-level declaration in `configuration.nix` is sufficient and avoids duplication.

```nix
#nixpkgs.config.allowUnfree = true; # the declaration on configuration.nix suffices
```

---

### Block 4 — XDG profile launcher script

**What is this?** A `home.file` entry with `executable = true` and an inline `text` declaration, placing a bash script at `~/.local/bin/launch-gnome`.

**What does it do?** On every `nixos-rebuild switch`, Home Manager writes the script to `~/.local/bin/launch-gnome` and sets the executable bit. The script itself overrides all four XDG base directories (_`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME`_) to point into `~/.*/profiles/gnome/` subdirectories, then `exec`s `gnome-session`. This gives the GNOME session a fully isolated XDG namespace — _GNOME reads and writes config exclusively within the `profiles/gnome/` subtrees, and any future Hyprland or KDE Plasma session using the default XDG paths cannot touch GNOME's config state._

**Why is it here?** The launcher is the singular remaining logic in `hm.nix` after modularisation — it was kept here rather than extracted to its own file because it is genuinely singular (_no siblings to group with_) and does not fit cleanly into any of the four concern-based sub-modules. It is not theming, not extensions, not dconf, and not a static asset. It is session infrastructure — _the natural home for it is the composition root._

> _This script is the entry point for every GNOME session on this machine. Before exec-ing gnome-session, it overrides all four XDG base directories to point into ~/.*/profiles/gnome/ instead of the bare ~/.*._
>
> _Why this matters: every GNOME component (shell, nautilus, mimeapps.list, autostart, keyring) respects XDG_CONFIG_HOME etc. when deciding where to read and write config. By redirecting those paths, GNOME gets a completely isolated config namespace that Hyprland and KDE Plasma cannot touch._
>
> _home.file places this script at $HOME/.local/bin/launch-gnome. executable = true sets the +x bit automatically._
>
> _The NixOS configuration.nix will reference this path in a custom wayland-session .desktop entry so GDM shows it as a login option._

```nix
home.file.".local/bin/launch-gnome" = {
  executable = true;
  text = ''
    #!/usr/bin/env bash
    export XDG_CONFIG_HOME="$HOME/.config/profiles/gnome"
    export XDG_DATA_HOME="$HOME/.local/share/profiles/gnome"
    export XDG_CACHE_HOME="$HOME/.cache/profiles/gnome"
    export XDG_STATE_HOME="$HOME/.local/state/profiles/gnome"
    exec gnome-session
  '';
};
```

---

## Dependencies

**Imported files:**

- `./extensions.nix` — _extension packages, UUID activation, per-extension dconf._
- `./assets.nix` — _wallpaper and avatar file placement._
- `./theming.nix` — _GTK theme, cursor, fonts, libadwaita assets, shell theme dconf._
- `./dconf.nix` — _all non-extension dconf settings._

**Home Manager options set by this file:**

- `home.file.".local/bin/launch-gnome"` — _XDG profile launcher script._

**nixpkgs packages required:**

- None directly — _packages are declared in sub-modules._

**External flake inputs used:**

- None directly.

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.de.gnome.enable`|`bool`|`false`|Top-level kill-switch; gates the launcher script declaration|

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

- **Thin composition root pattern:** `hm.nix` is intentionally minimal. The goal is that adding a new GNOME HM concern requires creating a new sub-module file and appending one line to the `imports` list here — _no other changes to this file._ This keeps `hm.nix` stable and makes the module tree's growth visible in git history as new files rather than as churn in an existing large file.
- **XDG profile isolation rationale:** The launcher redirects all four XDG directories because GNOME Shell, Nautilus, the keyring daemon, and autostart entries all respect the XDG spec. Redirecting only `XDG_CONFIG_HOME` would leave `XDG_DATA_HOME` shared with other DEs — Nautilus bookmarks and recently-used files would bleed across sessions. Full isolation ensures that switching between GNOME and Plasma, Hyprland, etc produces genuinely independent configuration states.
- **`exec gnome-session`:** The `exec` is intentional — _it replaces the bash process with `gnome-session` rather than spawning it as a child._ This means the launcher script has zero runtime footprint after session start and the process tree is clean.
- **GDM `.desktop` entry:** The launcher is not self-activating. It must be referenced by a custom Wayland session `.desktop` file (in `/usr/share/wayland-sessions/` or similar) that GDM presents as a login option. That `.desktop` entry is managed in `configuration.nix` — _outside the scope of this file._

---

## Known Limitations

- The XDG profile paths (`~/.config/profiles/gnome/`, etc.) are hardcoded strings in the script. If the profile directory structure changes, the script must be updated manually — _there is no variable or option binding these paths to a configurable value._
- The script does not perform any pre-flight checks (_e.g., verifying `gnome-session` is on `PATH`_). A missing `gnome-session` binary would result in a failed login with no user-visible error message beyond the GDM session restart.
- Wayland session `.desktop` registration is handled externally in `configuration.nix` and is not tracked by this module. If the `.desktop` entry is missing or misconfigured, GDM will not present the custom session option and the launcher will never be invoked.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Sub-modules composed|`./extensions.nix`, `./assets.nix`, `./theming.nix`, `./dconf.nix`|
|Module router|`./default.nix` — imports this file|
|System counterpart|`./system.nix`|
|GDM session entry|`configuration.nix` — registers the launcher as a Wayland session|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/hm.nix
Context: Home Manager
Created: 2026-06-09
Updated: 2026-06-09
-->
