<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# AnyDesk — `anydesk-hm.nix`

> _Installs the AnyDesk client into the user profile via Home Manager, in interactive (non-unattended) mode only._

**Module path:** `modules/apps/productivity/anydesk-hm.nix`
**Evaluation context:** `Home Manager`
**Status:** `Stable` 
**Last reviewed:** `2026-08-02`

---

## Responsibility

**Does:**

- Installs `pkgs.anydesk` into `home.packages` when both the productivity group and this app are enabled
- Documents, in a source comment, exactly what unattended access would require if it's ever turned on later

**Does not:**

- Does not declare any options — see `options.nix`
- Does not configure unattended access (permanent password, systemd daemon wiring) — this module only ever produces interactive/normal mode
- Does not set `nixpkgs.config.allowUnfreePredicate` — that's a single function, not a mergeable list, so setting it per-module risks clobbering other modules that also need unfree packages allowed. It's assumed to be set once, globally, wherever the flake already permits unfree packages

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity.anydesk`|
|Imports `options.nix`|`No` — HM already sees `options.nix` via the existing productivity module tree|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.productivity.enable && cypher-os.apps.productivity.anydesk.enable)`|
|Profile default|Set in `modules/profile/*.nix` (outside this session's scope)|

---

## Block Analysis

<!-- Walk through each logical block in the file in order. For each block: what is this, what does it do, why is it here. -->

---

### Block 1 — `cfg` binding

**What is this?** A `let` binding aliasing `config.cypher-os.apps.productivity.anydesk` to `cfg`.

**What does it do?** Nothing at evaluation time beyond the alias itself — it's a readability convenience so the rest of the file doesn't repeat the full attribute path.

**Why is it here?** Standard pattern across every module in this tree — keeps the kill-switch guard and any option reads short and consistent with `rustdesk-hm.nix`/`rustdesk-system.nix`.

```nix
let
  cfg = config.cypher-os.apps.productivity.anydesk;
in
```

---

### Block 2 — kill-switch guard

**What is this?** The module's single top-level `config = lib.mkIf (...) { ... }` expression.

**What does it do?** Short-circuits the entire body of the module to an empty set unless both the parent `productivity.enable` and this app's `anydesk.enable` are true — nothing inside evaluates or contributes to the final config otherwise.

**Why is it here?** This is the standard two-level gate used across every app module in this tree (group-level switch + per-app switch), so a single `productivity.enable = false` can kill the whole category without touching individual app flags.

```nix
config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {
  ...
};
```

---

### Block 3 — `home.packages`

**What is this?** A one-element list assigned to Home Manager's `home.packages`.

**What does it do?** Installs the `anydesk` derivation into the user's profile — the GUI app, launchable like any other installed package.

**Why is it here?** This is the entire functional payload of the module — AnyDesk needs no further HM configuration (no dotfiles, no session variables) to run in its default interactive mode.

```nix
home.packages = [ pkgs.anydesk ];
```

---

### Block 4 — unattended access annotation

**What is this?** A long-form source comment (no executing code) inside the `config` body.

**What does it do?** Nothing at runtime — it's documentation embedded at the point of relevance, describing the two concrete changes (permanent password + `systemd.packages`/`systemd.services.anydesk` wiring at the system level) that unattended access would require.

**Why is it here?** The decision made this session was explicitly "normal mode only, no unattended support" — this comment exists so that decision, and the reasoning/mechanics behind reversing it, doesn't have to be re-researched from scratch if unattended access is ever wanted later. It's addressed directly to future-me since it's genuine forward-looking guidance, not a description of what the code does.

```nix
# --- Unattended access (not enabled here) ---------------------------
# Current setup is interactive/normal mode only: launching the app
# generates a fresh session ID + one-time password each time, and every
# incoming connection requires an explicit Accept click on this machine.
#
# If unattended access is wanted later, it's a two-part change:
#   1. A permanent password set in AnyDesk's own security settings
#      (not a Nix option — lives in AnyDesk's runtime config, so this
#      would need `home.activation` or manual first-run setup).
#
#   2. The background service running independent of a login session —
#      the anydesk package ships a systemd unit at
#      `${pkgs.anydesk}/lib/systemd/system/anydesk.service`, but nixpkgs
#      does NOT wire it into systemd.services automatically. Enabling it
#      would mean adding, at the system (not HM) level:
#        systemd.packages = [ pkgs.anydesk ];
#        systemd.services.anydesk.wantedBy = [ "multi-user.target" ];
#
# That combination turns this from "reachable only while I have the app
# open and click Accept" into "reachable 24/7 by anyone with the fixed
# password" — a pro but, given it's a standing root-level daemon, it might
# expose an attack surface. For My threat model and since I don't currently
# need the unattended access, this is not implemented
#
# Consult session file (ANYDESK_&_RUSTDESK) for more
```

---

## Dependencies

**Imported files:**

- None — this file relies on `options.nix` already being visible in the Home Manager module tree, without an explicit `imports` line here

**NixOS options set by this file:** _(system.nix only)_

- None — this is an HM-only module

**Home Manager options set by this file:**

- `home.packages` — adds `pkgs.anydesk`

**nixpkgs packages required:**

- `pkgs.anydesk` — unfree; requires `nixpkgs.config.allowUnfreePredicate` to permit it somewhere upstream in the flake

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Top-level kill-switch for the whole productivity group|
|`cypher-os.apps.productivity.anydesk.enable`|`bool`|`false`|Installs `pkgs.anydesk` for this user|

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

- No `nixpkgs.config.allowUnfreePredicate` is set inside this module, even though `anydesk` requires it — that predicate is a single function value, and multiple modules each trying to append to it independently would clobber one another rather than merge. It's left as a flake-level concern
  
- Unattended access was deliberately scoped out this session (see Block 4) rather than left unimplemented silently — the comment documents both the "why not now" and the concrete "how, if later" so the decision doesn't need to be re-derived

---

## Known Limitations

- Not tested across all five OS lenses yet — only verified on the current active lens
- No `home.activation` step for any first-run AnyDesk configuration (e.g. setting a display name) — currently entirely manual, first-launch-through-the-GUI

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|None — AnyDesk has no `*-system.nix` (no NixOS service module exists for it in nixpkgs)|
|Profile default set in|`modules/profile/*.nix`|
|ADR|_None yet_|
|Incident|_None_|

---

<!-- METADATA 
Module: modules/apps/productivity/anydesk-hm.nix 
Context: Home Manager 
Created: 2026-08-02 
Updated: 2026-08-02 
-->