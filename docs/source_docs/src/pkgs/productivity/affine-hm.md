<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# AFFiNE Home Manager — `affine-hm.nix`

> _Installs the AFFiNE desktop app via `pkgs.affine` in the Home Manager context._

**Module path:** `modules/apps/productivity/affine-hm.nix` 
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-15`

---

## Responsibility

**Does:**

- Installs `pkgs.affine` _(the AFFiNE Electron desktop app, built from source in nixpkgs)_ into the user environment via `home.packages`

**Does not:**

- Declare options — see `options.nix`
- Handle system-level concerns (DNS, CA trust) — see `affine-system.nix`
- Manage the self-hosted Docker stack or any server-side configuration
- Configure the desktop app itself (server URL, workspace preferences) — those are configured interactively inside the app after first launch

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity`|
|Imports `options.nix`|No — options visible via HM module chain|
|Kill-switch guard|`lib.mkIf (config.cypher-os.apps.productivity.enable && config.cypher-os.apps.productivity.affine.enable)`|
|Profile default|`lib.mkDefault true` set in `modules/profile/default.nix`|

---

## Block Analysis

---

### Block 1 — kill-switch guard

**What is this?** A `lib.mkIf` expression wrapping the entire `config` attrset. The condition is the logical AND of two option reads from the `cypher-os.apps.productivity` namespace.

**What does it do?** When either `productivity.enable` or `affine.enable` is `false`, this file contributes nothing to the Home Manager configuration — `pkgs.affine` is not installed. When both are `true`, `pkgs.affine` is added to the user's `home.packages`.

**Why is it here?** Standard CypherOS two-level guard pattern. `productivity.enable` is the group kill-switch; `affine.enable` is the app-level toggle. This allows AFFiNE to be disabled independently without affecting other productivity apps (Obsidian, Claude, Penpot, Logseq).

```nix
config = lib.mkIf
  (config.cypher-os.apps.productivity.enable
    && config.cypher-os.apps.productivity.affine.enable)
  { ... };
```

---

### Block 2 — `home.packages`

**What is this?** An assignment to the `home.packages` list — the standard Home Manager mechanism for adding packages to the user environment.

**What does it do?** Installs `pkgs.affine` — the AFFiNE Electron desktop application — into the user environment. The binary becomes available as `affine` on `$PATH` and as a `.desktop` entry in the application launcher.

**Why is it here?** `pkgs.affine` is a nixpkgs package (channel: nixos-unstable / nixos-25.05+, maintainer: `@xiaoxiangmoe`) that builds AFFiNE from source. It wraps the Electron binary with Wayland flags (`--ozone-platform-hint=auto`, `--enable-features=WaylandWindowDecorations`) via `makeWrapper` — no additional environment configuration is needed. This is preferable to an AppImage wrapper (which would require manual hash management per release) or building from source outside nixpkgs (which would require maintaining a Nix derivation upstream changes would continuously break).

```nix
home.packages = with pkgs; [ affine ];
```

---

## Dependencies

**Imported files:** None — `options.nix` is visible via the Home Manager module chain without an explicit import in this file.

**Home Manager options set by this file:**

- `home.packages` — appends `pkgs.affine` to the user package list

**NixOS options set by this file:** None

**nixpkgs packages required:**

- `pkgs.affine` — AFFiNE Electron desktop app; available in nixpkgs from nixos-25.05 onward. Version must be compatible with the self-hosted server version. As of 2026-06-15: nixpkgs provides v0.26.6, server runs v0.26.7 — compatible minor versions.

**External flake inputs used:** None

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group kill-switch; `false` makes this entire file a no-op|
|`cypher-os.apps.productivity.affine.enable`|`bool`|`false`|App-level toggle; `false` skips `pkgs.affine` installation|

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

- `with pkgs; [ affine ]` style is used here rather than `[ pkgs.affine ]` — consistent with the surrounding codebase convention for single-package or short lists. No semantic difference.
  
- `options.nix` is intentionally not imported. In the Home Manager evaluation context, the `cypher-os.*` options are already visible through the module chain without a redundant import. This differs from `affine-system.nix` where the explicit import is required because the NixOS context cannot see HM-context declarations without it.
  
- **Version alignment:** `pkgs.affine` and the self-hosted server image must be on compatible minor versions. The nixpkgs package lags slightly behind upstream. Track the nixpkgs maintainer's update cadence. If a major server upgrade lands before nixpkgs catches up, the desktop app may experience API incompatibilities — test after every server upgrade.
  
- The desktop app does not auto-configure to point at `https://affine.local`. After first install, the user must open the app, go to the workspace switcher, select "Add Server", and enter `https://affine.local`. This is a one-time interactive step — there is no declarative path to pre-configure server URL in the Electron app.

---

## Known Limitations

- **No declarative server URL configuration:** The AFFiNE Electron app stores its server connection and workspace state in user-local application data, not in a config file that Home Manager can manage. The server URL (`https://affine.local`) must be entered manually on first launch and after any app data reset.
  
- **nixpkgs version lag:** `pkgs.affine` tracks upstream with some delay. Between a server upgrade and a nixpkgs package update, the versions may diverge. Monitor for compatibility issues after server upgrades.
  
- **GNOME lens only:** Tested on the GNOME CypherOS lens. The Wayland flags injected by the nixpkgs wrapper are GNOME/wlroots-compatible. KDE Plasma lens behavior not yet validated.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|`affine-system.nix`|
|Profile default set in|`modules/profile/default.nix`|
|ADR (self-hosted decision)|AFFiNE infra repo — `ADR_001_self_hosted_over_cloud.md`|

---

<!-- METADATA 
Module: modules/apps/productivity/affine-hm.nix 
Context: Home Manager 
Created: 2026-06-15 
Updated: 2026-06-15 
-->