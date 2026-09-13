<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# RustDesk — `rustdesk-hm.nix`

> _Installs the RustDesk (Flutter) client into the user profile via Home Manager — works against the public relay with zero further config._

**Module path:** `modules/apps/productivity/rustdesk-hm.nix`
**Evaluation context:** `Home Manager` 
**Status:** `Stable`
**Last reviewed:** `2026-08-02`

---

## Responsibility

**Does:**

- Installs `pkgs.rustdesk-flutter` into `home.packages` when both the productivity group and this app are enabled

**Does not:**

- Does not declare any options — see `options.nix`
- Does not configure or depend on the self-hosted server in `rustdesk-system.nix` — the client works against RustDesk's public hbbs/hbbr by default regardless of whether the server module is enabled anywhere
- Does not wire the client to a self-hosted server automatically — pointing the client at a self-hosted `relayHosts` target is a manual in-app step (Settings > Network), since that's client runtime state, not something Nix manages

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity.rustdesk`|
|Imports `options.nix`|`No` — HM already sees `options.nix` via the existing productivity module tree|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.productivity.enable && cypher-os.apps.productivity.rustdesk.enable)`|
|Profile default|Set in `modules/profile/*.nix` (outside this session's scope)|

---

## Block Analysis

---

### Block 1 — `cfg` binding

**What is this?** A `let` binding aliasing `config.cypher-os.apps.productivity.rustdesk` to `cfg`.

**What does it do?** Alias only — no runtime effect.

**Why is it here?** Same convention as `anydesk-hm.nix` and `rustdesk-system.nix` — keeps the guard and any option reads short.

```nix
let
  cfg = config.cypher-os.apps.productivity.rustdesk;
in
```

---

### Block 2 — kill-switch guard

**What is this?** The module's single top-level `config = lib.mkIf (...) { ... }` expression.

**What does it do?** Short-circuits the module body to an empty set unless `productivity.enable && rustdesk.enable` are both true. Note this guard does **not** reference `cfg.server.enable` — that's a separate, finer-grained gate that lives entirely in `rustdesk-system.nix`. The client is intentionally independent of whether self-hosting is turned on.

**Why is it here?** Standard two-level gate pattern used across the productivity module tree.

```nix
config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {
  ...
};
```

---

### Block 3 — `home.packages`

**What is this?** A one-element list assigned to Home Manager's `home.packages`.

**What does it do?** Installs the `rustdesk-flutter` derivation — the current (non-deprecated) client build — into the user's profile.

**Why is it here?** Entire functional payload of the module. Unlike AnyDesk, no `allowUnfree` concern — both the RustDesk client and OSS server are under an OSI license nixpkgs builds without an unfree flag.

```nix
home.packages = [ pkgs.rustdesk-flutter ];
```

---

### Block 4 — client/server relationship note

**What is this?** A source comment (no executing code) inside the `config` body.

**What does it do?** Nothing at runtime — documents that this client has no automatic link to `rustdesk-system.nix`, and that pointing it at a self-hosted server is a manual step.

**Why is it here?** This was an explicit open question this session ("hopefully they can work together") — the answer is "yes, but not automatically," and that's easy to forget later when `rustdesk.server.enable` eventually flips true and the client still silently defaults to the public relay until manually reconfigured.

```nix

# No allowUnfree concern; RustDesk client + server are both OSI licensed.

# This client works out of the box against RustDesk's public hbbs/hbbr —
# no dependency on rustdesk-system.nix being enabled. If the server
# module IS enabled on a given host, point this client's ID/Relay Server
# fields (Settings > Network, in-app) at that host manually — there's no
# automatic wiring between the HM client config and the NixOS server
# config, since that's the client's own runtime state, not a Nix option.
```

---

## Dependencies

**Imported files:**

- None — relies on `options.nix` already being visible in the Home Manager module tree

**NixOS options set by this file:** _(system.nix only)_

- None — this is an HM-only module

**Home Manager options set by this file:**

- `home.packages` — adds `pkgs.rustdesk-flutter`

**nixpkgs packages required:**

- `pkgs.rustdesk-flutter`

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Top-level kill-switch for the whole productivity group|
|`cypher-os.apps.productivity.rustdesk.enable`|`bool`|`false`|Installs `pkgs.rustdesk-flutter` for this user|

Note: this file does **not** read `cypher-os.apps.productivity.rustdesk.server.*` — those options only affect `rustdesk-system.nix`.

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

- The client module deliberately doesn't gate on `cfg.server.enable` — client and server are orthogonal concerns (see Block 2). This mirrors the real-world relationship: the RustDesk client always works against _some_ relay, whether that's the public one or a self-hosted one, and which one is a client-side runtime setting, not a Nix-managed dependency
- `rustdesk-flutter` chosen over the older `rustdesk` package per current upstream guidance that the Flutter build is the actively maintained client

---

## Known Limitations

- Not tested across all five OS lenses yet
- No declarative way to pre-seed the client's server address (ID/Relay Server fields) — first-run configuration toward a self-hosted server remains a manual GUI step

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|`rustdesk-system.nix`|
|Profile default set in|`modules/profile/*.nix`|
|ADR|_None yet_|
|Incident|_None_|

---

<!-- METADATA 
Module: modules/apps/productivity/rustdesk-hm.nix 
Context: Home Manager 
Created: 2026-08-02 
Updated: 2026-08-02 
-->