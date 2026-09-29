# ADR_027_2026_09_29: Use Separate Debuggers for Plain C# and Unity

**Date:** 2026-09-29
**Status:** Proposed
**Deciders:** CypherWhisperer

<!-- Promote to Accepted after the Neovim Unity debugging route is trialled (see the RFC). -->

---

## Context

- The IDE convention is that VSCode and Neovim share the same language tooling, including the debugger where possible. For C# that turned out not to be fully possible.

- Unity debugging works only on the Mono backend (IL2CPP is not supported) and uses the Mono soft debugger.
- Microsoft's Unity debug adapter is bundled with the VSCode Unity extension. 
- `netcoredbg` targets .NET (CoreCLR), and the nvim-dap wiki lists it under the `coreclr` adapter.

- For Neovim, the community route for Unity is [unity-dap](https://github.com/overlooked-being/unity-dap), a Mono-based adapter that needs a global Mono install and has reported NuGet dependency issues when building. It is not packaged in nixpkgs as far as research found.

---

## Decision

Two debuggers, by runtime:

- **Plain C# (CoreCLR):** `netcoredbg` through nvim-dap in Neovim; the extension's bundled debugger in VSCode.
- **Unity (Mono):** the VSCode Unity extension's debugger in VSCode; a Mono-based Unity adapter in Neovim, treated as experimental until trialled.

Nix provides `netcoredbg` (`gameDev.debug.netcoredbg.enable`) and `mono` (`gameDev.debug.mono.enable`). The Unity adapter itself is not packaged.

---

## Reasoning

- The runtimes differ, so no single debugger covers both.
- Recording this openly is better than pretending the shared-debugger convention holds.
- VSCode remains the reliable route for Unity debugging, and Neovim keeps the option to try the community adapter without committing to it.

---

## Alternatives Considered

### One debugger for everything (netcoredbg)

Would satisfy the convention. Rejected: it cannot debug Unity, which runs on Mono.

### Unity debugging in VSCode only

Simplest and most reliable. Not rejected outright: it is the explicit fallback if the Neovim route proves unreliable, and it may become the final decision after the trial.

### Package unity-dap in Nix

Would make the Neovim route declarative. Deferred: the adapter has build problems reported upstream, and packaging effort is not justified before the route is proven useful.

---

## Consequences

**Positive:**

- Each runtime uses a debugger that actually supports it.
- VSCode gives a dependable Unity debugging path.

**Negative / Trade-offs:**

- The "same binaries in both IDEs" convention is not met for debugging.
- Unity debugging in Neovim may end up unsupported or manually maintained.
- Adds `mono` as an installed package purely for the experimental adapter.

**Neutral / Operational:**

- Revisit after the Neovim trial; if Unity debugging there is unreliable, mark it out of scope in the RFC and reduce this ADR to VSCode-only for Unity.
- Related: [ADR_026](ADR_026_2026_09_29_share_roslyn_ls_and_csharpier_across_vscode_and_neovim.md), [game_development_setup](../../source_docs/src/pkgs/dev/game_dev/game_development_setup.md).

---

<!-- NOTES: Remove this section in finalized ADRs. Sources: https://github.com/walcht/neovim-unity , https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation -->