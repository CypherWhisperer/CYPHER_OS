<!-- deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap. -->

# Logseq — `logseq.nix`

> _Installs the Logseq desktop app and declaratively manages its graph configuration directory under the CypherOS `~/DATA/` backup tree._

**Module path:** `modules/apps/productivity/logseq.nix` 
**Evaluation context:** `Home Manager`
**Status:** `Stable`
**Last reviewed:** `2026-06-14`

---

## Responsibility

**Does:**

- Installs the `logseq` package from nixpkgs
- Ensures the graph base directory exists under `~/DATA/` by placing a `.keep` sentinel file
- Manages `logseq/config.edn` declaratively as a Nix store symlink _(read-only by Logseq — safe)_
- Copies `logseq/custom.css` _(Catppuccin Mocha)_ as a real mutable file via `home.activation`, bypassing the Nix store symlink limitation

**Does not:**

- Declare the `cypher-os.apps.productivity.logseq` option — _that lives in `options.nix`_
- Deploy any server-side component — _Logseq is local-first; there is no sync server_
- Manage sync across devices — _Syncthing handles the filesystem layer and is declared separately_
- Manage graph content _(pages, journals, assets)_ — _Logseq writes those itself at runtime_

---

## Evaluation Context

|Property|Value|
|---|---|
|Evaluated by|`homeManagerModules`|
|Options namespace|`cypher-os.apps.productivity.logseq`|
|Imports `options.nix`|Yes — required|
|Kill-switch guard|`lib.mkIf (cypher-os.apps.productivity.enable && cypher-os.apps.productivity.logseq.enable)`|
|Profile default|Not set — opt-in only|

---

## Block Analysis

---

### Block 1 — `let` bindings

**What is this?** Two local bindings evaluated before the module body: `cfg` aliases the logseq option subtree; `graphBase` constructs the absolute path to the graph root.

**What does it do?** Eliminates repetition — both `cfg` and `graphBase` are referenced in four separate places in the `config` body. Without the binding, each reference would spell out the full path inline.

**Why is it here?** `graphBase` in particular is a long, structured path that must be consistent across the `.keep` sentinel, the `config.edn` placement, and the `home.activation` script. A single `let` binding makes it impossible for the four references to drift out of sync.

```nix
let
  cfg = config.cypher-os.apps.productivity.logseq;
  graphBase = "${config.home.homeDirectory}/DATA/FILES/DE_FILES/SHARED/APPS/logseq/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/graph";
in
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` body with a two-part boolean condition.

**What does it do?** The entire module — package, files, and activation script — evaluates to no-ops unless both `cypher-os.apps.productivity.enable` and `cypher-os.apps.productivity.logseq.enable` are `true`. Disabling either shuts down the whole module without touching any other productivity tool.

**Why is it here?** This is the standard CypherOS two-tier kill-switch pattern: the parent `productivity.enable` guards the subsystem as a whole; the child `logseq.enable` guards this specific tool. Neither alone is sufficient — you can disable the whole productivity group without needing to enumerate individual tools, and you can disable Logseq specifically without disturbing Obsidian, Penpot, or anything else in the group.

```nix
config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {
```

---

### Block 3 — `home.packages`

**What is this?** A list containing the `logseq` package from nixpkgs, added to the user's Home Manager package set.

**What does it do?** Makes the `logseq` binary available in the user's environment. On the current nixpkgs revision (26.05), `logseq` pins `electron_39`, which has been marked insecure (EOL). The package installs only because `nixpkgs.config.permittedInsecurePackages` in `hosts/nixos/configuration.nix` explicitly allows `"electron-39.8.10"`.

**Why is it here?** The package itself requires no special override — previous attempts to override the Electron version (trying `electron_34`, `electron_36`, `electron_37`, `electron_38` in sequence) all failed: the lower versions had been removed from nixpkgs entirely, and `electron_37`/`electron_38` were also flagged insecure. Permitting the package at the nixpkgs config level is the only viable path until upstream Logseq cuts a release that bumps its Electron pin. Tracked at nixpkgs#528213.

```nix
home.packages = with pkgs; [ logseq ];
```

---

### Block 4 — graph directory sentinel

**What is this?** A `home.file` declaration placing an empty `.keep` file at the graph root.

**What does it do?** Forces Home Manager to create the full directory path at `$graphBase` on `home-manager switch`. Without this, the directory may not exist when Logseq first launches, and Logseq would either error or create it in an unexpected location.

**Why is it here?** Home Manager does not create directories on its own — it only creates them as a side effect of placing files. A `.keep` sentinel is the idiomatic way to declare directory existence declaratively. The file is empty and never read by Logseq.

```nix
home.file."${graphBase}/.keep" = {
  text = "";
};
```

---

### Block 5 — `config.edn`

**What is this?** A `home.file` declaration placing Logseq's graph-level configuration file as a Nix store symlink.

**What does it do?** Writes the EDN map that controls Logseq's core behaviour for this graph: file format (Markdown), workflow (todo), directory layout, telemetry flag, and feature flags. Logseq reads this file on startup and on graph reload — it does not write back to it during normal operation, making a read-only Nix store symlink safe here.

**Why is it here?** Declaring `config.edn` in the module rather than leaving it to Logseq's UI has two benefits: it makes the configuration reproducible (any fresh graph opened at this path gets the same settings), and it explicitly sets `:telemetry-enabled false`, which is the privacy-first baseline. The inline `text` approach is used rather than `source = ./config/config.edn` because the content is short enough to keep co-located with the module for easy review.

```nix
home.file."${graphBase}/logseq/config.edn" = {
  text = ''
    {:meta/version 1
     :preferred-format :markdown
     :preferred-workflow :todo
     :journals-directory "journals"
     :pages-directory "pages"
     :hidden []
     :telemetry-enabled false
     ;; :default-templates {:journals ""}
     :feature/enable-block-timestamps? false
     :feature/enable-whiteboards? false
    }
  '';
};
```

---

### Block 6 — `home.activation` — Catppuccin Mocha CSS

**What is this?** A `home.activation` script that runs after Home Manager's `writeBoundary` phase, copying `catppuccin-mocha.css` from the Nix store into the graph directory as a real, mutable file.

**What does it do?** Places `logseq/custom.css` at the path Logseq auto-loads for custom theming. Unlike `home.file`, which produces a Nix store symlink, `home.activation` runs a shell command (`cp --remove-destination`) that writes the bytes out to a regular file owned by the user. This means `custom.css` has permissions `644` and is not a symlink — Logseq's CSS file watcher can resolve and hot-reload it correctly.

**Why is it here?** The initial implementation used `home.file` for `custom.css`, which placed a symlink into the Nix store. Logseq's Electron CSS engine failed to load the theme — the app launched in its default dark mode without any Catppuccin colours applied. Investigation confirmed both `config.edn` and `custom.css` were symlinks (`ls -la` output). Switching to `home.activation` with `cp --remove-destination` resolved the issue: the file is now a real path the CSS watcher can follow. `--remove-destination` is required because the previous activation may have written a read-only copy from the store; without it, `cp` would fail to overwrite. `$DRY_RUN_CMD` is the Home Manager convention that suppresses the command during `--dry-run` passes.

```nix
home.activation.logseqCatppuccinCss = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  $DRY_RUN_CMD cp --remove-destination \
    ${./config/catppuccin-mocha.css} \
    "${graphBase}/logseq/custom.css"
  $DRY_RUN_CMD chmod 644 "${graphBase}/logseq/custom.css"
'';
```

---

## Dependencies

**Imported files:**

- `options.nix` — declares `cypher-os.apps.productivity.logseq.enable`; without this import the `cfg` binding and the kill-switch guard reference an undefined option and evaluation fails

**Home Manager options set by this file:**

- `home.packages` — adds `logseq` to the user package set
- `home.file."…/.keep"` — creates the graph base directory
- `home.file.".../logseq/config.edn"` — places graph-level Logseq configuration
- `home.activation.logseqCatppuccinCss` — copies Catppuccin Mocha CSS as a real file

**nixpkgs packages required:**

- `pkgs.logseq` — the Logseq desktop app; requires `nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ]` in the NixOS system configuration

**External flake inputs used:**

- None

**Co-located files required:**

- `modules/apps/productivity/config/catppuccin-mocha.css` — the Catppuccin Mocha CSS file, sourced from `https://logseq.catppuccin.com/ctp-mocha.css` and pinned locally for offline use

---

## Option Surface

|Option|Type|Default|Effect when `true`|
|---|---|---|---|
|`cypher-os.apps.productivity.enable`|`bool`|`false`|Top-level productivity kill-switch|
|`cypher-os.apps.productivity.logseq.enable`|`bool`|`false`|Enables this module — installs app and places config files|

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

- `config.edn` is safe as a `home.file` symlink because Logseq treats it as read-only config — _it reads the file on startup and does not write back to it._ `custom.css` is not safe as a symlink because Logseq's CSS file watcher needs to resolve a real filesystem path; the Nix store path confused it silently.
  
- The `graphBase` path follows the CypherOS `~/DATA/` convention, placing all Logseq data under the standard backup tree. The graph directory is not managed by Home Manager beyond the `.keep` sentinel — _Logseq writes its own content there at runtime._
  
- There is no `logseq-system.nix`. Unlike Penpot, Logseq requires no `/etc/hosts` entry, no local CA trust, and no systemd service. The system boundary does not exist for this tool.
  
- The Catppuccin CSS file is pinned locally at `config/catppuccin-mocha.css` to avoid any outbound request at activation time. To update: `curl -o modules/apps/productivity/config/catppuccin-mocha.css https://logseq.catppuccin.com/ctp-mocha.css`, then commit.
  
- Electron override attempts were exhausted before settling on `permittedInsecurePackages`. The override attribute name changed from `electron_27` → `electron_39` between nixpkgs revisions, and candidates `electron_34`, `electron_36` had been removed; `electron_37`, `electron_38` were also insecure. The permitted insecure package declaration is the correct approach until Logseq upstream ships a release with a supported Electron.

---

## Known Limitations

- `logseq` depends on `electron-39.8.10`, which is EOL and marked insecure in nixpkgs. The explicit `permittedInsecurePackages` allowance is a known compromise. Revisit when Logseq upstream releases a version with a supported Electron (tracked: nixpkgs#528213).
  
- The file header comment in the source file still reads `logseq-hm.nix` — the actual filename is `logseq.nix`. The header should be corrected.
  
- `custom.css` is overwritten on every `home-manager switch`. Any manual edits made directly to the file will be lost. All theme customisation must go through the Nix-managed source at `config/catppuccin-mocha.css`.
  
- Whiteboards and block timestamps are explicitly disabled via `config.edn` feature flags. Re-enable via the option if needed — there is currently no CypherOS option exposing these; they require direct `config.edn` edits.

---

## Related

|Type|Reference|
|---|---|
|Options declared in|`./options.nix`|
|Counterpart file|None — no system-level component|
|Profile default set in|`modules/profile/default.nix`|
|ADR|None|
|Incident|None|

---

<!-- METADATA Module:
modules/apps/productivity/logseq.nix 
Context: Home Manager 
Created: 2026-06-14 
Updated: 2026-06-14 
-->