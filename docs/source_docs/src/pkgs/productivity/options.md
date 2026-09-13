<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Productivity Options — `options.nix`

> _Declares the `cypher-os.apps.productivity` option namespace: one group-level enable and three app-level enables for Claude, Obsidian, and Penpot._

**Module path:** `modules/apps/productivity/options.nix`
**Evaluation context:** `Both (options declaration)`
**Status:** `Stable`
**Last reviewed:** `2026-06-10`

---

## Responsibility

**Does:**

- Declares `cypher-os.apps.productivity.enable` as the group-level kill-switch for all productivity applications
- Declares `cypher-os.apps.productivity.claude.enable`, `obsidian.enable`, and `penpot.enable` as app-level kill-switches
- Makes these options available to every module that is imported into the same evaluation context

**Does not:**

- Set any defaults — _all options declared here are `false` by default (standard `mkEnableOption` behaviour); defaults are set by `hm.nix` via `lib.mkDefault`_
- Configure any application — _no `config` attrset exists in this file_
- Import or depend on any other module within the group

---

## Evaluation Context

| Property              | Value                                                                                           |
| --------------------- | ----------------------------------------------------------------------------------------------- |
| Evaluated by          | `both` — _imported by `default.nix` (HM path) and directly by `penpot-system.nix` (NixOS path)_ |
| Options namespace     | `cypher-os.apps.productivity`                                                                   |
| Imports `options.nix` | Is `options.nix`                                                                                |
| Kill-switch guard     | None — _this file only declares options, it does not consume them_                              |
| Profile default       | No `lib.mkDefault` here — _set in `modules/apps/productivity/hm.nix`_                           |

---

## Block Analysis

---

### Block 1 — `options.cypher-os.apps.productivity`

**What is this?** A single `options` attrset containing five `lib.mkEnableOption` declarations nested under `cypher-os.apps.productivity`. `lib.mkEnableOption` is a nixpkgs library function that produces a `bool` option with description set to `"Whether to enable <description>."`, default `false`, and example `true`.

**What does it do?** Makes the following option paths available throughout any module that shares an evaluation context with this file:

- `config.cypher-os.apps.productivity.enable` — _the group switch. When `false`, every `mkIf` guard in `hm.nix`, `claude.nix`, `obsidian.nix`, `penpot-hm.nix`, and `penpot-system.nix` that includes this option in its condition evaluates to `{}`, effectively making all productivity modules no-ops._
- `config.cypher-os.apps.productivity.claude.enable` — _app-level switch for Claude Desktop. Read by `claude.nix`._
- `config.cypher-os.apps.productivity.obsidian.enable` — _app-level switch for Obsidian. Read by `obsidian.nix`._
- `config.cypher-os.apps.productivity.penpot.enable` — _app-level switch for Penpot. Read by `penpot-hm.nix` and `penpot-system.nix`._
- `config.cypher-os.apps.productivity.logseq.enable` — _app-level switch for logseq. Read by `logseq.nix`._
- `config.cypher-os.apps.productivity.affine.enable` — _app-level switch for AFFiNE. Read by `affine-hm.nix` and `affine-system.nix`._
- `config.cypher-os.apps.productivity.zathura.enable` — _app-level switch for Zathura. Read by `zathura.nix`._

**Why is it here?** The Nix module system requires options to be declared before they can be read. Centralising all declarations for a module group in a single `options.nix` keeps the contract for that group explicit and auditable in one place. Any module that reads a `cypher-os.apps.productivity.*` option must have this file in its import chain — _either via `default.nix` (for HM-context modules) or directly (for NixOS-context modules like `penpot-system.nix` which cannot rely on the HM import chain)._

```nix
options.cypher-os.apps.productivity = {
  enable         = lib.mkEnableOption "CypherOS Productivity Applications";
  claude.enable  = lib.mkEnableOption "Claude Desktop";
  obsidian.enable = lib.mkEnableOption "Obsidian Desktop App";
  penpot.enable  = lib.mkEnableOption "Penpot Design App";
  logseq.enable = lib.mkEnableOption "Logseq knowledge base";
  affine.enable = lib.mkEnableOption "AFFiNE knowledge base";
  zathura.enable = lib.mkEnableOption "Zathura PDF reader";
};
```

---

## Dependencies

**Imported files:**

- None

**NixOS options set by this file:**

- None — this file only declares options

**Home Manager options set by this file:**

- None — this file only declares options

**nixpkgs packages required:**

- None

**External flake inputs used:**

- None

---

## Option Surface

This file IS the option surface for the `cypher-os.apps.productivity` namespace. All options declared here:

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Group kill-switch — gates `hm.nix`, `claude.nix`, `obsidian.nix`, `penpot-hm.nix`, `penpot-system.nix`|
|`cypher-os.apps.productivity.claude.enable`|`bool`|`false`|Enables Claude Desktop installation and MCP config in `claude.nix`|
|`cypher-os.apps.productivity.obsidian.enable`|`bool`|`false`|Enables Obsidian installation and full vault management in `obsidian.nix`|
|`cypher-os.apps.productivity.penpot.enable`|`bool`|`false`|Enables Penpot Desktop in `penpot-hm.nix` and local DNS + CA trust in `penpot-system.nix`|

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

- The two-level guard pattern (`productivity.enable && <app>.enable`) used in all sibling modules derives directly from this declaration. `productivity.enable` provides a single switch to disable the entire group; the app-level options allow individual apps to be toggled without touching the group switch.
- All four options use `lib.mkEnableOption` rather than `lib.mkOption` with `type = lib.types.bool`. The difference is that `mkEnableOption` enforces a standardised description string and `default = false`, which is the correct semantic for a feature that must be explicitly opted into.
- This file has no `config` attrset — _it is a pure options declaration._ This is intentional and must remain so. Adding config to `options.nix` would mix declaration and activation concerns and is the pattern that the three-file split (_`options.nix` / `hm.nix` / `system.nix`_) is designed to prevent.

---

## Known Limitations

- There is currently no assertion validating that individual app enables (_e.g. `claude.enable = true`_) are not set while the group enable is `false`. Setting `claude.enable = true` with `productivity.enable = false` silently does nothing — the `mkIf` guard in `claude.nix` short-circuits on the group switch. A future session is planned to introduce assertions and more decisive central profile management across CypherOS.

---

## Related

|Type|Reference|
|---|---|
|Options consumed by|`./hm.nix`, `./claude.nix`, `./obsidian.nix`, `./penpot-hm.nix`, `./penpot-system.nix`|
|Profile defaults set in|`./hm.nix`|
|ADR|_None_|
|Incident|_None_|

---

<!-- METADATA
Module: modules/apps/productivity/options.nix
Context: Both
Created: 2026-06-10
Updated: 2026-06-10
-->
