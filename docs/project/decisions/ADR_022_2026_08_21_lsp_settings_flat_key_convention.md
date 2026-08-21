# ADR_022_2026_08_21: LSP Settings — Standardize on Flat Keys, Never Mix Forms

**Date:** 2026-08-21
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

While cleaning up the Go-specific `gopls` settings block in `vscode.nix`, a review pass found the same underlying setting expressed under two different key forms with different, disagreeing values — e.g. `gopls."ui.diagnostic.analyses"`  coexisting with `gopls."analyses"`, and `gopls."ui.inlayhint.hints"` *(a fabricated key that wasn't real)* coexisting with `gopls."hints"` *(the actual key, set to different values).*

Whichever one `gopls` actually read silently won, meaning part of the intended config was dead weight without any error or warning.

`gopls`'s own documentation organizes settings under hierarchical section headings (`ui.diagnostic.*`, `ui.completion.*`, `formatting.*`, `build.*`) for readability, but doesn't consistently make clear whether a given heading is also a literal, accepted JSON key or purely a documentation-organizational label.

Evidence found this session was genuinely mixed:
- `golang/vscode-go`'s own wiki documents `"ui.diagnostic.staticcheck": true` as a literal, working dotted key, while `gopls`'s canonical `settings.md` examples for `analyses` and `hints` both use the flat, unprefixed form.
- This inconsistency exists within gopls alone — *there's no reason to expect it will be any more consistent for the next language server CypherOS configures.*

## Decision

Every LSP/language-server settings key in CypherOS's editor configs uses the flat, unprefixed form only.

A flat key and its dotted-hierarchical counterpart are never both set for the same underlying field in the same config, even in cases where both are believed to be valid aliases for each other.

## Reasoning

Given confirmed inconsistency in which form is canonical — *even within a single language server's own documentation* — the reliably safe move is to eliminate the possibility of duplication by construction, rather than re-verify each key's alias status individually.

That verification cost would otherwise have to be paid again for every setting, on every future language server CypherOS adds support for *(Rust, PHP, etc.).*

Flat keys were the form most consistently confirmed across the settings actually checked against source this session (`hints`, `analyses`, `gofumpt`, `local`, `staticcheck`, `completeUnimported`, `directoryFilters`), making that the sane default absent strong evidence otherwise for a specific server.

## Alternatives Considered

### Verify each dotted-vs-flat key per language server, use whichever form the docs show as canonical

Research the authoritative key form setting-by-setting for `gopls`, and repeat the exercise for every future language server as CypherOS's language support grows. 

**Rejected:** expensive to redo per server, and the evidence this session showed even `gopls`'s own documentation isn't internally consistent about it — a *"verify per key"* policy doesn't resolve the ambiguity, it just re-discovers it every time a new setting gets added.

### Allow dotted keys where a source explicitly confirms they work, flat-only otherwise

A middle-ground, case-by-case policy — e.g. dotted `ui.diagnostic.staticcheck` stays because a wiki page confirms it, everything else defaults to flat.

**Rejected as not worth the inconsistency:**
- a config where "most keys are flat, but this one is dotted because a wiki page said so" is harder to audit at a glance than a uniform rule, for a benefit — marginally more "doc-canonical"-looking config — that doesn't change gopls's actual runtime behavior at all.

## Consequences

**Positive:**

- Eliminates an entire bug class *(duplicate-key drift between two spellings of the same setting)* by construction, rather than relying on careful review every time a setting is added.
  
- Config is easier to grep/diff — no need to remember which of two spellings a given setting might appear under.
  
- Applies uniformly to any future language server, not just `gopls`

**Negative / Trade-offs:**

- Occasionally means translating a copy-pasted doc example *(which may show the dotted/hierarchical form)* into its flat equivalent by hand when adding a new setting, rather than pasting verbatim.
  
- If a language server ever ships a setting that's genuinely only accepted in dotted form — *no flat alias exists* — this convention needs a documented, deliberate exception. Not yet encountered, but worth watching for as more language servers get added

**Neutral / Operational:**

- When adding a new `gopls` *(or future-LSP)* setting going forward, default to the flat spelling shown in the server's own canonical JSON examples; if only a dotted example is available, treat that as a signal to double-check for a flat alias before assuming one exists.