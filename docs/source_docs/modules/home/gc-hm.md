<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# HM Generation Auto-Expiry — `gc-hm.nix`

> _Configures `services.home-manager.autoExpire` to prune old Home Manager generations on a schedule, complementing (not duplicating) the system-level `nix.gc`._

**Module path:** `modules/home/gc-hm.nix` 
**Evaluation context:** Home Manager 
**Status:** Stable 
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Enables `services.home-manager.autoExpire`, a systemd `--user` timer that runs `home-manager expire-generations`
- Sets the retention window (`timestamp`) and run frequency to mirror the system-level `nix.gc` configuration's intent

**Does not:**

- Run `nix-collect-garbage` itself — `store.cleanup` is left `false`; store-path reclamation remains `nix.gc`'s job (`hosts/nixos/configuration.nix`), not this file's
  
- Affect the NixOS system's own profile/generation history — `nixos-rebuild`'s system generations are a separate mechanism entirely, untouched by this option

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules` — this file is imported by `modules/home/default.nix`, and therefore reaches both HM evaluation contexts identically|
|Options namespace|`services.home-manager.autoExpire.*`|
|Imports `options.nix`|No — declares no `cypher-os.*` options; this is a direct use of an option Home Manager itself provides|
|Kill-switch guard|None — unconditionally enabled; no `cypher-os.*` toggle gates it|
|Profile default|Not applicable|

---

## Block Analysis

### Block 1 — Function signature

**What is this?** `{ ... }:` — no named arguments are needed; this file references no `pkgs`, `lib`, or `inputs`.

**What does it do?** Standard HM module function head, accepting and ignoring whatever arguments HM supplies.

**Why is it here?** Kept minimal deliberately — every value this file sets is a literal, not derived from `pkgs`/`lib`/`inputs`, so there's nothing to destructure.

```nix
{ ... }:
```

---

### Block 2 — `services.home-manager.autoExpire`

**What is this?** The full option block: `enable`, `timestamp`, `frequency`, and `store.cleanup` (with `store.options` left commented).

**What does it do?** `enable = true` creates the systemd `--user` timer. `timestamp = "-7 days"` sets the retention window — generations older than this are expired (their profile symlink removed) each time the timer fires; passed straight to `date -d`. `frequency = "weekly"` sets the systemd `OnCalendar` schedule the timer runs on. `store.cleanup = false` explicitly opts out of this module also invoking `nix-collect-garbage`.

**Why is it here?** `nix.gc` (the system-level GC scheduler in `hosts/nixos/configuration.nix`) only reclaims Nix store paths with no live GC root — it does not prune Home Manager's own generation list. Each HM generation symlink is itself a GC root for as long as it exists, so without this module, old generations would accumulate indefinitely and keep their referenced store paths alive regardless of how aggressively `nix.gc` runs. `timestamp = "-7 days"` deliberately mirrors `nix.gc`'s `options = "--delete-older-than 7d"` so the two mechanisms express the same retention intent even though neither is aware of the other. `frequency = "weekly"` was chosen over the module's own default (`"monthly"`) specifically because a monthly cadence paired with a 7-day retention window would let up to ~3 weeks of expired generations accumulate between runs, undermining the point of a 7-day window. `store.cleanup = false` is the most consequential single value here: enabling it would mean two independent `nix-collect-garbage` invocations (this timer's and `nix.gc`'s) running on unrelated schedules against the same store, which is wasted work at best and a source of confusing overlap at worst — store-path reclamation is left entirely to `nix.gc`, and this module's scope is deliberately narrowed to generation-list pruning only.

```nix
services.home-manager.autoExpire = {
  enable = true;
  timestamp = "-7 days";
  frequency = "weekly";
  store.cleanup = false;
  # store.options = "--delete-older-than 30d";
};
```

---

## Dependencies

**Imported files:** None

**NixOS options set by this file:** Not applicable — HM-only file

**Home Manager options set by this file:**

- `services.home-manager.autoExpire.enable`
- `services.home-manager.autoExpire.timestamp`
- `services.home-manager.autoExpire.frequency`
- `services.home-manager.autoExpire.store.cleanup`

**nixpkgs packages required:** None directly

**External flake inputs used:** None

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|`services.home-manager.autoExpire.enable`|`bool`|`true` (set here)|Creates and activates the systemd `--user` auto-expire timer|
|`services.home-manager.autoExpire.timestamp`|`str`|`"-7 days"` (set here)|Retention window passed to `date -d`; generations older than this are expired on each timer run|
|`services.home-manager.autoExpire.frequency`|`str`|`"weekly"` (set here; module default is `"monthly"`)|`systemd OnCalendar` schedule for the timer|
|`services.home-manager.autoExpire.store.cleanup`|`bool`|`false` (set here)|Whether this timer also runs `nix-collect-garbage` after expiring generations — left off to avoid duplicating `nix.gc`|

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

_The commented `store.options` line is DEFERRED-tier — only meaningful if `store.cleanup` is later flipped to `true`; kept visible as a ready-to-use pairing rather than removed._

---

## Design Notes

- This is a `systemd --user` timer, not a system one — it only fires while `cypher_whisperer` has an active or lingering session. If CypherOS usage patterns ever shift toward long logged-out periods, `loginctl enable-linger cypher_whisperer` would be needed for this timer to still fire reliably; not currently configured, since the GNOME-desktop-lens usage pattern makes an active session the common case.
  
- `nix.gc.automatic = false` is set in `hosts/nixos/configuration.nix` deliberately ("safety for continuous dev," per its own comment) — this module's `enable = true` does not currently track that same manual-control philosophy; it runs on its own schedule regardless of the system-level toggle. Whether that inconsistency should be resolved (e.g. by also gating this module behind a shared flag) is an open question, not yet decided.

---

## Known Limitations

- No shared toggle between `nix.gc.automatic` and this module's `enable` — they can drift independently, and currently do (system-level GC is manual-only; HM generation expiry is automatic)
  
- Requires an active or lingering user session to fire at all; silently does nothing on a system with no session and no linger enabled, with no alerting if that happens

---

## Related

|Type|Reference|
|---|---|
|Options declared in|Provided directly by the Home Manager module set — not a `cypher-os.*` option, no local `options.nix` counterpart|
|Counterpart file|`hosts/nixos/configuration.nix` (`nix.gc` — the system-level store-cleanup counterpart to this file's generation-list-only scope)|
|Profile default set in|Not applicable|
|ADR|None — this was a direct configuration addition, not a formal architectural decision|
|Incident|None|

---

<!-- METADATA 
Module: modules/home/gc-hm.nix 
Context: Home Manager 
Created: 2026-07-31 
Updated: 2026-07-31 
-->