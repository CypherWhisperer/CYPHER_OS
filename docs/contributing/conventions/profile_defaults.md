# Convention: Profile- and Lens-Conditional Defaults

**Status:** Active
**Applies to:** any category whose `enable` (or a leaf's `enable`) should default differently across `cypher-os.profile.active` / `cypher-os.lens.current`.
**Related:** [gating_and_assertions.md](./gating_and_assertions.md), [ADR_023](../../project/decisions/ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md), [ADR_024](../../project/decisions/ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)

---

## 1. The core rule: profile/lens are signals, never a place to centralize logic

`src/profile/{system,hm}.nix` resolve `cypher-os.profile.active` / `cypher-os.lens.current` and expose them as `cypherOsProfile` / `cypherOsLens` via `_module.args`. That is their entire job.

**They must never reference another category's namespace** (no `cypher-os.de.gnome.*`, no `cypher-os.devops.*`, nothing) — a profile-conditional default belongs in the *category's own* `system.nix`/`hm.nix`, not in `src/profile/`.

This reverses the pre-refactor `modules/profile/{default,system}.nix` pattern, which pushed every category's defaults into one hub file. That pattern is retired, not migrated.

## 2. The pattern

In the category's own `system.nix` / `hm.nix`:

```nix
{ config, lib, cypherOsProfile, ... }:

let
  cfg = config.cypher-os.de.gnome;
in
{
  config.cypher-os.de.gnome.enable = lib.mkDefault (cypherOsProfile == "desktop");
}
```

Prefer the `cypherOsProfile`/`cypherOsLens` module args (from `src/profile/*`'s `_module.args`) over reaching into `config.cypher-os.profile.active` directly — consistent with the note already flagged in [the gating convention doc](./gating_and_assertions.md).

This also means every profile-aware category file takes `cypherOsProfile` (and/or `cypherOsLens`) as a function argument, same as any other `_module.args`-supplied value.

For a default that should hold under more than one profile:
```nix
lib.mkDefault (cypherOsProfile == "desktop" || cypherOsProfile == "server")

# or, for three or more:
lib.mkDefault (builtins.elem cypherOsProfile [ "desktop" "server" ])
```

For a lens-conditional default (the fonts case from ADR-024):
```nix
lib.mkDefault (cypherOsLens != "nixos")
```

## 3. This is not "gating" — don't conflate with §3–§4 of [gating_and_assertions.md](./gating_and_assertions.md)

Gating (`lib.mkIf cfg.enable { ... }`) controls whether a leaf's *config activates*, given whatever `enable` currently resolves to. This convention controls what `enable` *defaults to* in the first place.

They compose, they don't replace each other — a category still gates on `cfg.enable` as usual; this convention only governs how that `enable`'s default value is derived.

## 4. Known cost: no single file answers "what does profile X contain"

Because every category's file states its own profile default independently, there is no longer one place to read off the full membership of a profile — unlike the old hub file, which (however tangled) at least let you see every default in one block.

**Mitigation, not a fix:**
- Maintain a plain reference table in `docs/source_docs/` — hand-maintained, not derived — listing category → default-per-profile, updated whenever a category's default changes.
- It won't be enforced by Nix and can drift, so treat it as documentation debt to watch, not a source of truth to trust blindly; `grep -rn 'cypherOsProfile ==' src/` is the actual ground truth if the two ever disagree.

## 5. Assertions still apply as normal

A profile-conditional default doesn't replace the enable-implies-profile assertion from [gating_and_assertions.md](./gating_and_assertions.md) §3/§11 — they answer different questions.

The default answers "what should this be, absent an override"; the assertion answers "is the current value, however it got set, actually valid." Keep both.
