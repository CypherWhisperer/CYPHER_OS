<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# RustDesk — `rustdesk-system.nix`

> _Runs the self-hosted RustDesk signaling/relay server (hbbs/hbbr) at the NixOS system level, gated independently of the client._

**Module path:** `modules/apps/productivity/rustdesk-system.nix`
**Evaluation context:** `NixOS system`
**Status:** `In Development` — module is complete and correct; `server.enable` is set to `lib.mkDefault false` in the profile, so nothing is actually running yet
**Last reviewed:** `2026-08-02`

---

## Responsibility

**Does:**

- Configures `services.rustdesk-server` (hbbs + hbbr) when the productivity group, `rustdesk.enable`, and `rustdesk.server.enable` are all true
- Explicitly imports `options.nix` so the NixOS evaluation context can resolve `cypher-os.apps.productivity.rustdesk.*`

**Does not:**

- Does not declare any options itself — see `options.nix`
- Does not install or configure the client — see `rustdesk-hm.nix`
- Does not point any client at this server automatically — `relayHosts` only controls what hbbs _advertises_; getting a given machine's client to actually use this server is a separate, manual step on that client

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`nixosModules`|
|Options namespace|`cypher-os.apps.productivity.rustdesk.server`|
|Imports `options.nix`|`Yes — required`|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.productivity.enable && cypher-os.apps.productivity.rustdesk.enable && cypher-os.apps.productivity.rustdesk.server.enable)`|
|Profile default|`cypher-os.apps.productivity.rustdesk.server.enable = lib.mkDefault false;` — set explicitly this session|

---

## Block Analysis

---

### Block 1 — `cfg` binding

**What is this?** A `let` binding aliasing `config.cypher-os.apps.productivity.rustdesk` to `cfg`.

**What does it do?** Alias only — no runtime effect.

**Why is it here?** Same convention as the two HM files — keeps the guard and the `services.rustdesk-server` stanza's option reads short (`cfg.server.openFirewall` etc. instead of the full path each time).

```nix
let
  cfg = config.cypher-os.apps.productivity.rustdesk;
in
```

---

### Block 2 — `imports = [ ./options.nix ]`

**What is this?** The module's `imports` attribute, pointing at the sibling `options.nix`.

**What does it do?** Merges `options.nix`'s option declarations into this file's evaluation — without it, any reference to `config.cypher-os.apps.productivity.rustdesk.*` here would throw an undefined-option error at eval time, since NixOS's module system doesn't automatically share option declarations with whatever imports Home Manager already has in place.

**Why is it here?** This is the load-bearing difference between this file and the two `*-hm.nix` files: HM already has `options.nix` visible somewhere upstream in its own module tree, but the NixOS system configuration is a separate evaluation entirely and needs its own explicit import to see the same `cypher-os.*` namespace.

```nix
imports = [ ./options.nix ];
```

---

### Block 3 — kill-switch guard

**What is this?** The module's top-level `config = lib.mkIf (...) { ... }` expression, with a three-term `&&` condition.

**What does it do?** Short-circuits the entire `services.rustdesk-server` stanza to an empty set unless all three are true: the productivity group, `rustdesk.enable`, and — the addition specific to this file — `rustdesk.server.enable`. Currently the third term is false via the profile's `mkDefault`, so this whole module evaluates to nothing on the target host today.

**Why is it here?** The extra `cfg.server.enable` term is what makes self-hosting a genuinely separate decision from "I use the RustDesk client at all" — enabling `rustdesk.enable` alone gets you the client working against the public relay; standing up your own server is a deliberate additional flip.

```nix
config = lib.mkIf (
  config.cypher-os.apps.productivity.enable
  && cfg.enable
  && cfg.server.enable
) {
  ...
};
```

---

### Block 4 — `services.rustdesk-server` stanza

**What is this?** An attrset assigned to the upstream NixOS option `services.rustdesk-server`, itself containing nested `signal` (hbbs) and `relay` (hbbr) attrsets.

**What does it do?** Enables and configures both server halves: `enable = true` turns the module on; `openFirewall` opens the required ports (21115–21119) as governed by `cfg.server.openFirewall`; `signal.relayHosts` tells hbbs what to advertise to clients as the relay location; both `extraArgs` fields pass arbitrary CLI flags straight through to their respective binaries for anything not modeled as a first-class NixOS option.

**Why is it here?** This is the actual functional payload of the file — everything upstream of this block exists only to make this stanza safely reachable and correctly gated.

```nix
services.rustdesk-server = {
  enable = true;
  openFirewall = cfg.server.openFirewall;

  signal = {
    enable = true;
    relayHosts = cfg.server.relayHosts;
    extraArgs = cfg.server.signalExtraArgs;
  };

  relay = {
    enable = true;
    extraArgs = cfg.server.relayExtraArgs;
  };
};
```

---

### Block 5 — key-pair location comment

**What is this?** A source comment (no executing code) following the `services.rustdesk-server` stanza.

**What does it do?** Nothing at runtime — documents where hbbs writes its generated Ed25519 keypair on first start.

**Why is it here?** The public half of that keypair (`id_ed25519.pub`) is required by every client connecting to this server — without this note, the "where do I find the key" question would mean re-discovering the path from upstream docs each time this server is actually turned on.

```nix
# Key pair (id_ed25519 / id_ed25519.pub) is generated on first hbbs
# start, at /var/lib/private/rustdesk/. The .pub contents are what every
# client needs entered as the server's public key to connect.
```

---

## Dependencies

**Imported files:**

- `options.nix` — required; without it, `config.cypher-os.apps.productivity.rustdesk.*` is undefined in the NixOS evaluation context

**NixOS options set by this file:**

- `services.rustdesk-server.enable` — `true` when the guard passes
- `services.rustdesk-server.openFirewall` — mirrors `cfg.server.openFirewall`
- `services.rustdesk-server.signal.{enable,relayHosts,extraArgs}` — hbbs configuration
- `services.rustdesk-server.relay.{enable,extraArgs}` — hbbr configuration

**Home Manager options set by this file:** _(hm.nix only)_

- None — this is a NixOS-only module

**nixpkgs packages required:**

- None directly — `services.rustdesk-server` pulls its own package internally (overridable via the upstream module's own `package` option, not currently exposed through `cypher-os.*`)

**External flake inputs used:**

- None

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Top-level kill-switch for the whole productivity group|
|`cypher-os.apps.productivity.rustdesk.enable`|`bool`|`false`|Must be true alongside `server.enable` for this file to do anything|
|`cypher-os.apps.productivity.rustdesk.server.enable`|`bool`|`mkDefault false` (set in profile)|Turns on `services.rustdesk-server` (hbbs + hbbr) on this host|
|`cypher-os.apps.productivity.rustdesk.server.openFirewall`|`bool`|`true`|Opens hbbs/hbbr ports in the firewall|
|`cypher-os.apps.productivity.rustdesk.server.relayHosts`|`listOf str`|`[ ]`|Address(es) hbbs advertises as the hbbr location — empty means hbbs starts but advertises nothing usable|
|`cypher-os.apps.productivity.rustdesk.server.signalExtraArgs`|`listOf str`|`[ ]`|Extra CLI flags passed to hbbs|
|`cypher-os.apps.productivity.rustdesk.server.relayExtraArgs`|`listOf str`|`[ ]`|Extra CLI flags passed to hbbr|

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

- The `imports = [ ./options.nix ]` line (Block 2) is the single most important structural difference from the two `*-hm.nix` files in this trio — it's the concrete answer to "why does *-system.nix need this and *-hm.nix doesn't," and is worth keeping as the canonical example if this question comes up for future `*-system.nix` files elsewhere in the tree*
  
- `pkgs` was removed from the function header — an earlier draft included it, but nothing in this file reads `pkgs` directly (the upstream `services.rustdesk-server` module manages its own package internally), so it was dropped rather than left as unused dead weight
  
- The three-term `&&` guard (Block 3) is one level deeper than the two-term guard used in the HM modules — deliberately, since self-hosting is a materially bigger decision (opens firewall ports, runs a standing service) than just having the client installed

---

## Known Limitations

- No option currently exposed for overriding `services.rustdesk-server.package` through the `cypher-os.*` namespace — would need to fall through to the upstream option directly if ever needed
- Not tested end-to-end yet (server has never actually been enabled) — correctness is based on matching the upstream module's option shape, not on a live run
- `relayHosts` defaulting to `[ ]` means enabling `server.enable` without also setting `relayHosts` produces a running-but-useless server; no assertion currently guards against that combination

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|`rustdesk-hm.nix`|
|Profile default set in|`modules/profile/*.nix`|
|ADR|_None yet_|
|Incident|_None_|

---

<!-- METADATA 
Module: modules/apps/productivity/rustdesk-system.nix 
Context: NixOS 
Created: 2026-08-02 
Updated: 2026-08-02 
-->