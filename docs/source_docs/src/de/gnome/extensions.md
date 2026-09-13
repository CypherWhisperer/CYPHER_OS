<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# GNOME Extensions — `extensions.nix`

> _Installs GNOME Shell extension packages, activates them by UUID, and configures their per-extension dconf keys._

**Module path:** `modules/de/gnome/extensions.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-09`

---

## Responsibility

**Does:**

- Installs all GNOME Shell extension packages into the user profile via `home.packages`.
- Activates extensions by writing their UUIDs to `org/gnome/shell.enabled-extensions` via `dconf.settings`.
- Provides per-extension dconf configuration blocks for every extension that has configurable settings.
- Owns the `compactQsExt` derivation override that patches `metadata.json` to declare GNOME Shell 48/49/50 compatibility.

**Does not:**

- Install non-extension GNOME packages (_those belong in a general packages module or profile_).
- Configure the GTK/shell theme applied by the `user-theme` extension — _that dconf key lives in `theming.nix` because it consumes `ctpThemeName`._
- Manage system-level extension paths or `/usr/share/gnome-shell/extensions/` — _all extensions are user-profile installed via nixpkgs._

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

**Why is it here?** Sub-module self-containment — same rationale as all other sub-modules.

```nix
imports = [ ./options.nix ];
```

---

### Block 2 — `compactQsExt` derivation override

**What is this?** A `let` binding that calls `overrideAttrs` on `pkgs.gnomeExtensions.compact-quick-settings` to append a `postInstall` hook.

**What does it do?** After the extension is built, the hook uses `jq` to patch the extension's `metadata.json` in the Nix store output, adding `"48"`, `"49"`, and `"50"` to the `shell-version` array. GNOME Shell checks this array on session start — _if the running shell version is not listed, the extension is silently skipped regardless of whether it appears in `enabled-extensions`._ The patched derivation is then referenced in `home.packages` in place of the raw nixpkgs package.

**Why is it here?** The upstream `compact-quick-settings` extension (_nixpkgs v11 at time of writing_) only declares compatibility up to GNOME Shell 47. After a `nix flake update` pulled in GNOME Shell 50, the extension stopped loading silently. The override is a targeted workaround pending an upstream release that declares GNOME 50 support. Placing it in the `let` block of this file keeps the patch co-located with the package reference that uses it.

This is a **temporary measure**. The comment in source marks it for removal once the upstream nixpkgs derivation ships a GNOME 50–compatible version.

```nix

compactQsExt = pkgs.gnomeExtensions.compact-quick-settings.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    metadata="$out/share/gnome-shell/extensions/compact-quick-settings@...//metadata.json"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq '.["shell-version"] += ["48", "49", "50"]' "$metadata" > "$tmp"
    mv "$tmp" "$metadata"
  '';
});
```

---

### Block 3 — `home.packages` extension list

**What is this?** A `home.packages` list scoped to GNOME Shell extensions and the Extension Manager GUI.

**What does it do?** Installs each extension package into the user profile, making the extension's files available under `~/.nix-profile/share/gnome-shell/extensions/<UUID>/`. GNOME Shell scans this path on startup. Installing a package makes the extension _available_ — _it does not activate it._ Activation requires the UUID to appear in `dconf.settings."org/gnome/shell".enabled-extensions`.

**Why is it here?** Package installation and UUID activation are two halves of the same contract — _an installed package with no UUID entry shows as "installed but disabled" in the Extensions app; a UUID entry with no installed package throws an error on session start._ Keeping both in the same file makes the contract visible and easy to audit.

```nix
home.packages = with pkgs; [
  compactQsExt   # patched version — see Block 2
  # ... full list in source
];
```

---

### Block 4 — `dconf.settings."org/gnome/shell".enabled-extensions`

**What is this?** A dconf key containing the list of extension UUIDs GNOME Shell loads on startup.

**What does it do?** On session start, GNOME Shell reads this list, resolves each UUID to an extension directory, verifies `metadata.json` compatibility, and loads the extension's JavaScript. The order in the list is not significant — _all extensions are loaded before the shell becomes interactive._

**Why is it here?** The UUID list and the package list are the two sides of the installation/activation contract (see Block 3). Co-location prevents the list from drifting out of sync with the packages — _if you add a package, the UUID reminder is one scroll away._

Note: `wobbly-windows@mecheye.net` appears in the UUID list but not in `home.packages`. This extension is provided by `gnomeExtensions.compiz-windows-effect` — _the `compiz-windows-effect` package bundles both effects under the same derivation, with `wobbly-windows` being the secondary UUID._

```nix
"org/gnome/shell" = {
  enabled-extensions = [ "blur-my-shell@aunetx" ... ];
};
```

---

### Block 5 — per-extension `dconf.settings` blocks

**What is this?** A series of `dconf.settings` path entries, one per configurable extension, each containing the extension's settings schema keys.

**What does it do?** Applies configuration to each extension declaratively. Without these blocks, extensions load with their compiled-in defaults. The blocks cover: `hidetopbar`, `blur-my-shell` (_root + four sub-paths_), `Logo-menu`, `coverflowalttab`, `compiz-windows-effect`, and `clipboard-indicator`.

**Why is it here?** Extension configuration belongs with the extension that owns it. Placing these in `dconf.nix` would scatter extension concerns across two files with no structural benefit. The rule is: if a dconf path is under `org/gnome/shell/extensions/`, it lives here.

Notable specifics:

- **`blur-my-shell`** has sub-path keys (_`/panel`, `/appfolder`, `/dash-to-dock`, `/window-list`_) — all included.
- **`Logo-menu`**: `menu-button-icon-image = 19` selects the Linux penguin  logo. The index is extension-internal; changing it requires consulting the extension's settings UI.
- **`coverflowalttab`**: `switcher-background-color` uses `lib.hm.gvariant.mkTuple` because the dconf schema type is a `(ddd)` tuple — _plain Nix floats would fail type checking._
- **`compiz-windows-effect`**: `last-version = 29` is an internal version marker the extension writes itself; declaring it here pins it and prevents the extension from triggering a first-run migration on every session start.

```nix
"org/gnome/shell/extensions/hidetopbar"      = { ... };
"org/gnome/shell/extensions/blur-my-shell"   = { ... };
# ... etc.
```

---

## Dependencies

**Imported files:**

- `options.nix` — _declares `cypher-os.de.gnome.enable`._

**Home Manager options set by this file:**

- `home.packages` — _extension package list._
- `dconf.settings."org/gnome/shell".enabled-extensions` — _UUID activation list._
- `dconf.settings."org/gnome/shell/extensions/*"` — _per-extension _configuration.

**nixpkgs packages required:**

- `pkgs.gnomeExtensions.*` — _all extension packages listed in `home.packages`._
- `pkgs.jq` — _used at build time inside the `compactQsExt` `postInstall` hook._
- `pkgs.gnome-extension-manager` — _GUI for managing extensions outside Home _Manager declarations.

**External flake inputs used:**

- None directly. Extension packages come from nixpkgs.

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

- **Package/UUID contract:** The two lists (packages in `home.packages`, UUIDs in `enabled-extensions`) must be kept in sync manually. There is no compile-time check that every UUID has a corresponding package. The `pkgs.gnomeExtensions.<name>.extensionUuid` attribute (_available on nixpkgs extension derivations_) could be used to derive UUIDs programmatically, eliminating the dual-maintenance burden. This is a future improvement noted in the NixOS GNOME wiki.
- **`wobbly-windows` / `compiz-windows-effect` bundle:** The nixpkgs `compiz-windows-effect` derivation installs both the `compiz-windows-effect@hermes83.github.com` and `wobbly-windows@mecheye.net` UUIDs. Only the former appears in `home.packages`; both appear in `enabled-extensions`. This is correct — _installing the package is sufficient for both UUIDs._
- **`compactQsExt` removal trigger:** Monitor `https://github.com/mariospr/compact-quick-settings-gnome-shell-extension` for a release declaring GNOME 50 support. Once nixpkgs picks it up, remove the `let` binding and replace `compactQsExt` in `home.packages` with `gnomeExtensions.compact-quick-settings`.

---

## Known Limitations

- No compile-time validation that every UUID in `enabled-extensions` has a corresponding package in `home.packages`. A mismatch produces a runtime error on GNOME Shell startup (_logged to journald_), not a build failure.
- The `compactQsExt` patch is version-pinned implicitly by the nixpkgs revision in `flake.lock`. If nixpkgs updates the extension to a version that already declares `"50"` support, the patch is redundant but harmless — _`jq` will simply add a duplicate entry._
- `gnome-extension-manager` is included to allow manual extension toggling outside the declarative list. Extensions toggled on via the GUI will not persist across HM activations — _the `enabled-extensions` dconf key is overwritten on every `nixos-rebuild switch`._

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Shell theme dconf key|`./theming.nix` — `org/gnome/shell/extensions/user-theme`|
|Counterpart file|`./system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/de/gnome/extensions.nix
Context: Home Manager
Created: 2026-06-09
Updated: 2026-06-09
-->
