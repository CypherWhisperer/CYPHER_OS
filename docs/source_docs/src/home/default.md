<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Home Manager Tree Entry Point — `default.nix`

> _Pulls in the full `cypher-os.*` module tree for Home Manager, and declares `home.stateVersion`. Imported identically by both HM evaluation contexts._

**Module path:** `modules/home/default.nix` 
**Evaluation context:** Home Manager:
- imported by both `flake/hosts.nix`'s nested HM user block and `flake/home-configurations.nix`'s standalone evaluation
**Status:** Stable 
**Last reviewed:** 2026-07-31

---

## Responsibility

**Does:**

- Imports `../../modules` — the entire domain-organized `modules/` tree (`apps/`, `de/`, `devops/`, etc.), making every `cypher-os.*` option and its HM-side implementation available
- Imports `./gc-hm.nix`, adding the `services.home-manager.autoExpire` configuration to this same tree
- Declares `home.stateVersion = "24.11";`, the required HM state-versioning marker

**Does not:**

- Declare `nixpkgs.overlays`, `nixpkgs.config.allowUnfree`, or `nixpkgs.config.permittedInsecurePackages` — removed as part of [ADR_012_2026_07_31](../../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md); this file previously carried a duplicated copy of these as a workaround for the `claude-desktop` bug, now resolved upstream
- Set `home.username`, `home.homeDirectory`, or `cypher-os.profile.desktop.enable` — those are set independently by each of the two calling contexts (`flake/hosts.nix` Block 6, `flake/home-configurations.nix` Block 5), not here

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`, in both the NixOS-nested and standalone contexts|
|Options namespace|`cypher-os.*` (via `../../modules`), `services.home-manager.autoExpire.*` (via `./gc-hm.nix`)|
|Imports `options.nix`|Yes — transitively, every `options.nix` under `../../modules`|
|Kill-switch guard|None at this level — this file is the aggregation point other files' kill-switches are declared within, not itself guarded|
|Profile default|Not set here — see `flake/hosts.nix`/`flake/home-configurations.nix`|

---

## Block Analysis

### Block 1 — Function signature

**What is this?** `{ inputs, lib, ... }:` — a standard HM module function head.

**What does it do?** Accepts `inputs` (available for any option elsewhere in the imported tree that needs a flake input directly) and `lib` (the Nixpkgs library functions), plus `...` to tolerate any other module arguments HM supplies without needing to name them all.

**Why is it here?** `inputs` specifically flows from `extraSpecialArgs`, set identically in both calling contexts (`flake/hosts.nix` and `flake/home-configurations.nix`) — this is what makes this file portable between them without modification.

```nix
{ inputs, lib, ... }:
```

---

### Block 2 — `imports`

**What is this?** `imports = [ ../../modules ./gc-hm.nix ];`

**What does it do?** Merges the entire `modules/` tree's option declarations and implementations into this HM evaluation, plus the `services.home-manager.autoExpire` config from the adjacent `gc-hm.nix`.

**Why is it here?** `../../modules` (rather than a more specific subset) is what makes `cypher-os.profile.desktop.enable = true;`, set by the calling context, cascade into every app/DE/DM default across the whole tree — this file is intentionally "import everything, let the profile toggle and individual `cypher-os.*` options decide what actually activates," not a curated subset. `gc-hm.nix` is imported as a sibling rather than folded inline, keeping GC-specific concerns in their own file per the project's `modules/apps/*` domain-split convention, even though this particular concern doesn't have an app-specific home to live under.

```nix
imports = [
  ../../modules
  ./gc-hm.nix
];
```

---

### Block 3 — `home.stateVersion`

**What is this?** `home.stateVersion = "24.11";`

**What does it do?** Pins the HM state-versioning marker that gates several default-behavior changes across the HM module set (e.g. `programs.firefox.configPath`, `xdg.userDirs.setSessionVariables` — both flagged as deprecation warnings during recent activations, see the 2026-07-31 journal entry).

**Why is it here?** Left at `"24.11"` deliberately, not yet bumped toward `"26.05"` — doing so would silently flip several defaults at once (per the accumulated warnings), which is judged a distinct, deliberate migration decision rather than something to fold into other unrelated changes. Tracked as an open question, not yet an ADR.

```nix
home.stateVersion = "24.11";
```

---

## Dependencies

**Imported files:**

- `../../modules` — the full domain-organized module tree
- `./gc-hm.nix` — HM generation auto-expiry config

**NixOS options set by this file:** Not applicable — HM-only file

**Home Manager options set by this file:**

- `home.stateVersion`

**nixpkgs packages required:** None directly

**External flake inputs used:** None directly — `inputs` is accepted as an argument but not referenced in this file's own body; it's threaded through to whatever in `../../modules` needs it

---

## Option Surface

|Option|Type|Default|Effect when `true` / set|
|---|---|---|---|
|_(none declared directly in this file)_|||This file is a pure aggregation point — see `../../modules/options.nix` and each domain's `options.nix` for the actual `cypher-os.*` option surface|

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

_Not currently used in this file._

---

## Design Notes

- This file is now content-identical regardless of which context imports it — the pre-refactor version differed subtly by context (carrying overlay/config duplication only reachable from the standalone path). Restoring context-independence was a direct goal of [ADR_012_2026_07_31](../../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md), and this file is the clearest evidence it was achieved: there is nothing left in it that only makes sense in one of the two calling contexts.
- `home.stateVersion` staying at `"24.11"` is a live, open decision, not an oversight — see the 2026-07-31 journal entry's "Open Questions" section.

_See [ADR_012_2026_07_31](../../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) for the full decision record._

---

## Known Limitations

- Importing the entire `modules/` tree unconditionally means every `options.nix` in the repo is evaluated for both HM contexts even when most options resolve to `false`/inactive — acceptable at current scale, worth revisiting only if evaluation time becomes a real friction point
  
- No explicit list of which `cypher-os.*` subtrees are HM-relevant vs. NixOS-relevant lives in this file — that split is enforced by each module's own `hm.nix`/`system.nix` separation, not visible from here

---

## Related

| Type                   | Reference                                                                                                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Options declared in    | `../../modules/options.nix` (and throughout `modules/`)                                                                                                           |
| Counterpart file       | None direct — this file has no `system.nix` sibling of its own; `hosts/nixos/configuration.nix` is its rough NixOS-side counterpart at the tree-entry-point level |
| Profile default set in | Not set here — see `flake/hosts.nix`/`flake/home-configurations.nix`                                                                                              |
| ADR                    | [ADR_012_2026_07_31](../../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)                                         |
| Incident               | [INC_2026_07_27_001](../../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md)                  |

---

<!-- METADATA 
Module: modules/home/default.nix 
Context: Home Manager 
Created: 2026-07-31 
Updated: 2026-07-31 
-->