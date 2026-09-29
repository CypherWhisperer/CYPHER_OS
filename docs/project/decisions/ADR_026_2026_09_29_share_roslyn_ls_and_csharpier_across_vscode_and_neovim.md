# ADR_026_2026_09_29: Share Roslyn LS and CSharpier Across VSCode and Neovim

**Date:** 2026-09-29
**Status:** Proposed
**Deciders:** CypherWhisperer

<!-- Promote to Accepted after the verification checklist in game_development_setup.md passes. -->

---

## Context

- C# is needed for the Game Design and Development course, in two editors:
    - VSCode (declarative, through CypherOS) and Neovim (CypherIDE, Lua and `lazy.nvim`, configured in its own repo).
- The IDE convention is that both editors use common language tooling so behaviour does not drift.

C# has more than one language server:

- **Roslyn LS**, the server behind C# Dev Kit, packaged in nixpkgs as `roslyn-ls`.
- **OmniSharp**, the legacy server, which Neovim guides commonly install through Mason.
- **csharp-ls**, an alternative server also present in nixpkgs.

Mason-downloaded binaries fit poorly with NixOS and with a reproducible setup. The Neovim client [roslyn.nvim](https://github.com/seblj/roslyn.nvim) supports Nix users installing `roslyn-ls`.

---

## Decision

Both IDEs use **Roslyn LS** (`pkgs.roslyn-ls`) as the language server and **CSharpier** (`pkgs.csharpier`) as the formatter, both installed by the `gameDev.dotnet` module in Home Manager. Neither editor downloads its own C# language tooling.

---

## Reasoning

- Roslyn LS is the server C# Dev Kit already uses, so VSCode and Neovim resolve the same engine.
- One Nix-provided binary per tool keeps versions identical across editors and reproducible.
- It avoids the legacy OmniSharp generation and Mason-managed binaries, which conflict with the declarative goal.

---

## Alternatives Considered

### OmniSharp via Mason

The path documented by some Unity-Neovim plugins (for example apyra/nvim-unity). Rejected: older server generation, and downloaded binaries do not fit NixOS or the shared-binaries convention.

### csharp-ls

Exists in nixpkgs and could serve Neovim. Not evaluated in depth. It would differ from the server VSCode uses, so the standardization goal would be lost.

### Each editor's own native tooling

Lowest setup effort. Rejected because behaviour and versions could drift between editors, and the tooling would not be declarative.

---

## Consequences

**Positive:**

- Consistent diagnostics and formatting across both editors.
- The tooling is reproducible through Nix.

**Negative / Trade-offs:**

- roslyn.nvim needs projects reachable through a `.sln`, so Unity-generated solution files must be regenerated after adding scripts.
- The SDK version `roslyn-ls` requires is unverified; the `dotnet.sdk` default (`sdk_9_0`) is a placeholder.
- Nix issues to re-check on the channel in use: C# Dev Kit not finding the runtime ([#389351](https://github.com/NixOS/nixpkgs/issues/389351)) and a read-only cache folder in roslyn-ls ([#376199](https://github.com/NixOS/nixpkgs/issues/376199)).
- Whether roslyn.nvim works with the nixpkgs binary without overriding `cmd` is still to be verified.

**Neutral / Operational:**

- The VSCode C# extensions (C# Dev Kit and the Unity extension) are Microsoft proprietary and tied to Microsoft's VS Code build; that is documented in the source comments.
- Neovim side: `CypherIDE/docs/rfcs/RFC_NNN_neovim_unity_csharp_support.md`.
- Related: [ADR_027](ADR_027_2026_09_29_use_separate_debuggers_for_plain_Csharp_and_unity.md), [game_development_setup](../../source_docs/src/pkgs/dev/game_dev/game_development_setup.md).

---

<!-- NOTES: Remove this section in finalized ADRs. -->