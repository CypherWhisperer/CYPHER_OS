<!--
deliberate annotation; forcing the self to articulate why every construct exists before you're allowed to move past it. The payoff isn't the doc file; it's the cognitive forcing function. When you can't write a sentence explaining a code block, you've found a gap.
-->

# [Module Name] — `[*hm|*system|*options].nix`

> _One sentence. What this file does within the module._

**Module path:** `modules/[subsystem]/[module]/[filename].nix`
**Evaluation context:** `[Home Manager | NixOS system | Both (options declaration)]`
**Status:** `[Planned · In Development · Stable · Deprecated]`
**Last reviewed:** `YYYY-MM-DD`

---

## Responsibility

<!-- What is this file responsible for? What does it explicitly NOT do? The split between hm.nix and system.nix is the contract — define it clearly. -->

**Does:**

- _TODO_

**Does not:**

- _TODO (e.g., "Does not declare options — see options.nix")_

---

## Evaluation Context

<!-- NixOS and Home Manager evaluate in separate contexts. This section documents what that means for THIS file. -->

| Property              | Value                                                                          |
| --------------------- | ------------------------------------------------------------------------------ |
| Evaluated by          | `[nixosModules \| homeManagerModules \| both]`                                 |
| Options namespace     | `cypher-os.[subsystem].[...]`                                                  |
| Imports `options.nix` | `[Yes — required / No / Is options.nix]`                                       |
| Kill-switch guard     | `lib.mkIf (cypher-os.[parent].enable && cypher-os.[module].enable)`            |
| Profile default       | `lib.mkDefault [true \| false]` set in `modules/profile/[default\|system].nix` |

---

## Block Analysis

<!-- CORE SECTION
Walk through each logical block in the file in order.

A "block" is any named set of expressions that serves one purpose:
an import list, an option declaration group, a kill-switch guard,
a services.* stanza, a programs.* stanza, a packages list, etc.

For each block, answer three questions:
  1. What is this?   (the construct — what Nix expression/attribute is being used)
  2. What does it do? (the runtime effect — what happens on activation)
  3. Why is it here?  (the design decision — why this approach, why this position)

Be ruthless. If you cannot answer all three, the block is not yet understood.

For options.nix files, each option declaration group counts as a block.
Document the type, default value, and the semantic intent — not just
the option name.
-->

---

### Block 1 — `[block name]`

**What is this?** _TODO: e.g., "A list passed to the `imports` attribute of the module's top-level `attrset`."_

**What does it do?** _TODO: e.g., "Merges the listed files into this module's evaluation context, making their options visible."_

**Why is it here?** _TODO: e.g., "`options.nix` must be imported here because NixOS-context modules cannot see HM-context option declarations without it. Without this import, any `cypher-os.*` option reference in this file would throw an undefined option error at eval time."_

```nix
# paste the actual block here
```

---

### Block 2 — `[block name, e.g. "kill-switch guard"]`

**What is this?** _TODO_

**What does it do?** _TODO_

**Why is it here?** _TODO_

```nix
# paste the actual block here
```

<!--
Repeat for every logical block. Name each descriptively — not "Block 3"
but "services.prometheus config" or "lib.optionals cloud.aws.enable".

The name is a navigation aid and a forcing function: if you can't name
the block, you don't understand its scope yet.
-->

---

## Dependencies

<!-- What must exist for this file to evaluate without error? -->

**Imported files:**

- `options.nix` — _TODO: why_

**NixOS options set by this file:** _(system.nix only)_

- `services.[x]` — _TODO_

**Home Manager options set by this file:** _(hm.nix only)_

- `programs.[x]` — _TODO_

**nixpkgs packages required:**

- `pkgs.[x]` — _TODO_

**External flake inputs used:**

- _TODO or "None"_

---

## Option Surface

<!--
Which `cypher-os.*` options does this file READ? (It doesn't declare them — options.nix does.)

For options.nix files, this section IS the primary content — document
every option declared in the file.

For system.nix and hm.nix files, this section documents which cypher-os.*
options the file READS (it doesn't declare them — options.nix does).

As the module namespace grows, this table becomes the fastest way to
understand what a file controls without reading the Nix source.
-->

| Option                           | Type     | Default     | Effect when `true` / set |
| -------------------------------- | -------- | ----------- | ------------------------ |
| `cypher-os.[subsystem].enable`   | `bool`   | `false`     | Top-level kill-switch    |
| `cypher-os.[subsystem].[option]` | `[type]` | `[default]` | _TODO_                   |

---

## Comment Convention

<!--
Include this section in all new source files. Remove it once the
convention is stable across the codebase.
-->

Inline comments in source files use three header tiers to classify
non-active code without explanation bloat. Deep rationale belongs here
in the documentation, not in the source file.

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

<!-- Why is it structured this way? Short observations only — deep rationale belongs in an ADR. -->

- _TODO: e.g., "lib.optionals is used instead of separate mkIf blocks because the
  cloud submodule has three independent enable flags that compose independently."_
- _TODO: e.g., "Package X is EXCLUDED — see comment header in source for reason."_

_See [ADR-NNN](path/to/docs/adr/ADR-NNN.md) if a formal decision record exists._

---

## Known Limitations

<!-- Be honest. What edge cases aren't handled? What hasn't been tested on all five OS lenses? -->

- _TODO_

---

## Related

| Type                   | Reference                               |
| ---------------------- | --------------------------------------- |
| Options declared in    | `./options.nix`                         |
| Counterpart file       | `[*system.nix \| *hm.nix]`              |
| Profile default set in | `modules/profile/[default\|system].nix` |
| ADR                    | _TODO or remove row_                    |
| Incident               | _TODO or remove row_                    |

---

<!-- METADATA
Module:   modules/[subsystem]/[module]/[filename].nix
Context:  [Home Manager | NixOS | Both]
Created:  YYYY-MM-DD
Updated:  YYYY-MM-DD
-->
