# ADR_021_2026_08_21: Nix-Managed Go Tooling, Shared Across Editors

**Date:** 2026-08-21
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

CypherOS's stated goal for Go support was to **fully** support the language across both configured DEs — VSCode and Neovim (`cypher-ide`) — for serious development sessions.

Both editors' Go integrations *(the `golang.go` VSCode extension, and a from-scratch Neovim LSP/DAP/formatter setup)* depend on the same handful of external binaries doing the actual work:
- `gopls` (language server.)
- `dlv` (debugger.)
- `golangci-lint` (meta-linter.)
- `gofumpt`/`goimports` (formatters.)
- and a handful of code-generation tools (`gomodifytags`, `gotests`, `impl`)
- plus `govulncheck`.

Both ecosystems have their own built-in mechanism for acquiring these tools independently of Nix:
- the VSCode Go extension has `go.toolsManagement.autoUpdate`, which installs/updates tools via `go install` on first use.
- Neovim's common pattern is `mason.nvim`, which fetches its own copies from GitHub releases.
- Left to their defaults, each editor would independently decide which version of `gopls`/`dlv`/etc. to run, with no guarantee the two agree with each other or with whatever `go` toolchain the terminal is using.

## Decision

All Go dev tooling is installed exactly once, via home-manager *(`programs.go` plus `home.packages`),* and both VSCode and Neovim are configured to find those binaries on `$PATH` rather than installing their own copies.

Editor-side tool-management features are explicitly disabled for these tools *(`go.toolsManagement.autoUpdate = false` in VSCode; Neovim's config does not use Mason for Go tooling).*

## Reasoning

A single Nix-managed set of tool binaries means the terminal, VSCode, and Neovim are all looking at literally the same files on disk — *there's no scenario where `gopls` behaves differently in one editor than another because they resolved to different versions.*

Upgrades happen in exactly one place *(a nixpkgs bump or a flake input update),* not three.

This also matches the architecture already established in CypherOS — home-manager as the single source of truth for user-space software.

## Alternatives Considered

### Per-editor tool management *(VSCode auto-update + Neovim Mason.)*

Leave `go.toolsManagement.autoUpdate` on, and use `mason.nvim` to install `gopls`/`dlv`/etc. for Neovim, with each editor pinned to whatever it happens to fetch over the network at first use.

**Rejected:** this reintroduces exactly the version-drift problem the rest of CypherOS's tooling deliberately avoids, and ties tool availability to network access and editor-launch timing rather than Nix build/activation time — *a regression from how everything else in the flake behaves.*

### Nix-managed tools, but per-editor pinned versions

Still Nix-managed, but two separate package sets, so VSCode could theoretically track tools matched to one Go toolchain generation *(e.g. `go_1_24`)* while Neovim tracks another *(e.g. `go_latest`).*

Rejected — no actual workflow calls for two editors targeting two different toolchain generations simultaneously on one machine, and it would double the config surface *(two `extraTools` lists, two sets of version bumps to keep in sync)* for no real benefit.

## Consequences

**Positive:**

- One version of every Go tool, everywhere — terminal, VSCode, and Neovim can't silently disagree on `gopls`/`dlv`/etc. behavior
- Tool upgrades are a single `nix flake update` / rebuild, not three separate manual updates across the terminal, VSCode, and Neovim
- No network dependency for tool availability once the system is built — consistent with the rest of the flake's offline-capable posture

**Negative / Trade-offs:**

- Slower to pick up a brand-new `gopls`/`dlv` release than an editor's own auto-updater would be — bounded by `nixpkgs`' own update cadence *(or a flake input bump, for anything tracking `go_latest`-style rolling packages.)*
  
- A tool needed by only one editor would still get installed system-wide via `home.packages`, rather than scoped to just that editor's environment — *a minor disk/PATH surface cost, not a functional one.*

**Neutral / Operational:**

- Any future Go dev tool *(a new linter, a new codegen tool)* gets added once, to the shared tool list in `go-hm.nix` — not duplicated into each editor's own config.
  
- Sets the template for future languages under the same dev-languages namespace *(e.g. PHP)* — same pattern, not Go-specific