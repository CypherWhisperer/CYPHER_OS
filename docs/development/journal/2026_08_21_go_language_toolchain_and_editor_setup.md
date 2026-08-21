# 2026_08_21 Go Language Toolchain and Editor Setup

**Date:** 2026-08-21
**Duration:** ~3 hours
**Repos touched:** CypherOS flake, `cypher-ide`
**Modules touched:**
1. `modules/apps/dev/go-hm.nix` *(new.)*
2. `modules/apps/dev/go-system.nix` *(new.)*
3. `modules/apps/dev/options.nix` *(extension.)*
4. `modules/apps/editor/vscode.nix` *(extension.)*
5. `cypher-ide/lua/plugins/tree-sitter.lua`
6. `cypher-ide/lua/plugins/lsp-config.lua`
7. `cypher-ide/lua/plugins/linting-and-formatting.lua`
8. `cypher-ide/lua/plugins/dap-go.lua` *(new.)*

**Phase:** 

---

## What I Worked On

Full-stack Go language support across three levels:
- system-wide (Nix/home-manager)
- VSCode
- and Neovim (`cypher-ide`)

— toolchain, dev tools, formatting, linting, testing, debugging, and editor-specific settings for all three.

Followed with a dedicated critique/cleanup pass on the Go-specific VSCode/`gopls` settings block once a fuller draft existed to review.
## What Got Done

- Built the Nix-side Go module:
    - `programs.go` (home-manager) wiring GOPATH/GOPRIVATE/telemetry, plus the shared dev-tool set *(`gopls`, `delve`, `golangci-lint`, `gofumpt`, `gotools`, `gomodifytags`, `gotests`, `impl`, `govulncheck`)* installed once via `home.packages` — no per-editor tool installers. See [ADR_021](../../project/decisions/ADR_021_2026_08_21_nix_managed_go_tooling_shared_across_editors.md).
  
- Added the `golang.go` VSCode extension *(Tier 1, confirmed packaged in nixpkgs)* and a full `go.*`/`gopls.*` settings block to `vscode.nix`.
  
- Wrote a Neovim setup guide for `cypher-ide`:
    - treesitter `go` parser, native `vim.lsp.config`/`vim.lsp.enable` gopls config *(mirroring the VSCode `gopls` block),* formatter/linter wiring, and a net-new `dap-go.lua` — debugging wasn't present anywhere in the `cypher-ide` tree before this session.
  
- Documented the full `nixpkgs`/home-manager Go configuration surface as a matrix table (config / type / configured / effect / reasoning).

- Resolved all of the above; standardized every `gopls` key to its flat form. See [ADR_022](../../project/decisions/ADR_022_2026_08_21_lsp_settings_flat_key_convention.md).
  
- Produced a final config-state table reflecting the cleaned-up block, including a *"dropped entirely"* section documenting what got removed and why.

## Key Decisions Made

Two decisions were significant enough to promote to ADRs — see [ADR_021](../../project/decisions/ADR_021_2026_08_21_nix_managed_go_tooling_shared_across_editors.md) *(Nix-managed tooling shared across editors)* and [ADR_022](../../project/decisions/ADR_022_2026_08_21_lsp_settings_flat_key_convention.md) *(flat-key convention for LSP settings).*

Smaller decisions that stayed journal-level rather than becoming ADRs:

- Inlay hints: curated set (`constantValues`, `ignoredError`, `functionTypeParameters`, `parameterNames` on; `assignVariableTypes`, `compositeLiteralFields`, `compositeLiteralTypes`, `rangeVariableTypes` off) — picked by "catches a real bug class" vs. "restates the obvious on every line."
  
- `-race` dropped from the default `go.testFlags` — real cost *(slower runs, more memory)* not worth paying on every save; left as an explicit opt-in via a documented comment rather than a silent omission.
  
- `go.languageServerFlags` (`-rpc.trace`, `-v`) stripped from the steady-state config — *debug-session tooling, not a daily-driver default.*

## Where I Got Stuck

- Shipped an unverified gopls key *(`ui.inlayhint.hints`)* in the first pass of `vscode.nix` — only caught it during the dedicated critique round, by checking `gopls`'s source rather than trusting the vscode-go docs' section-heading naming. Worth being more conservative about asserting LSP setting names without a confirmed source going forward, especially given how inconsistent `gopls`'s own docs turned out to be about flat vs. dotted key forms (see [ADR_022](../../project/decisions/ADR_022_2026_08_21_lsp_settings_flat_key_convention.md)).
  
- The `vscode-go` settings.md fetch truncated before reaching the section that would have confirmed (or denied) `gopls.diagnosticsDelay` as a real key — *left it out rather than ship it unverified.*

## What I Learned

gopls documents most settings under hierarchical headings *(`ui.diagnostic.*`, `ui.completion.*`, `formatting.*`, `build.*`)* purely for documentation organization, but at least one of those headings *(`ui.diagnostic.staticcheck`)* is also confirmed usable as a literal dotted JSON key elsewhere in the docs — *meaning the flat-vs-dotted question genuinely isn't consistent even within one language server's own documentation.*

Treating "pick one form and never mix" as a hard rule ([ADR_022](../../project/decisions/ADR_022_2026_08_21_lsp_settings_flat_key_convention.md)) is cheaper than re-verifying alias status per key, per language server, forever.

## Open Questions

- `gopls.local = "github.com/CypherWhisperer"` — Not yet sure what this field implies. Worth revisiting after actual go development experience.
  
- `gopls.diagnosticsDelay` — real key name and default, unconfirmed this session.
  
- Namespace: currently `cypher-os.apps.dev.languages.go`; a rename to `cypher-os.pkgs.dev.languages.{go,php,...}` is being drafted for a future session.

## Next Session

- Wire `dap-go.lua` and its plugin-manager registration into `cypher-ide` — currently just the guide, not applied.
  
- Confirm `gopls.local` and `gopls.diagnosticsDelay` against the real conventions/current docs.
  
- Revisit the `cypher-os.pkgs.dev.languages.{go,php,...}` namespace rename once decided, and how it affects everything landed this session.

---

<!--
Commit range:
CypherOS flake: [short hash] → [short hash]
cypher-ide: [short hash] → [short hash]
-->