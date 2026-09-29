# [2026_09_29] Game Dev Tooling: Unity and C# Design

<!-- The journal is informal. This is the human layer on top of git history. Write like you're explaining the session to yourself six months from now. What happened, what you figured out, what you're still unsure about. Honest > polished. -->

**Date:** 2026-09-29
**Duration:** ~N hours <!-- fill in --> 
**Repos touched:**
1. CypherOS
2. CypherIDE (RFC only, no implementation)

**Modules touched:**
1. `src/pkgs/dev/game_dev/{options,hm,unity,dotnet,debug}.nix` (new)
2. `src/pkgs/dev/ide/vscode/extensions/lang/csharp.nix` (new)
3. `src/pkgs/dev/ide/vscode/extensions/game_dev/unity.nix` (new)

**Related Docs:**
1. [game_development_setup](../../source_docs/src/pkgs/dev/game_dev/game_development_setup.md)
2. `CypherIDE/docs/rfcs/RFC_NNN_neovim_unity_csharp_support.md`
3. [gating_and_assertions](../../contributing/conventions/gating_and_assertions.md)
4. [ADR_025_2026_09_29_unity_6000.3_lts_editor_pin](../../project/decisions/ADR_025_2026_09_29_unity_6000.3_lts_editor_pin.md)
5. [ADR_026_2026_09_29_share_roslyn_ls_and_csharpier_across_vscode_and_neovim](../../project/decisions/ADR_026_2026_09_29_share_roslyn_ls_and_csharpier_across_vscode_and_neovim.md)
6. [ADR_027_2026_09_29_use_separate_debuggers_for_plain_Csharp_and_unity](../../project/decisions/ADR_027_2026_09_29_use_separate_debuggers_for_plain_Csharp_and_unity.md)
7. [RBK_017_setting_up_a_new_unity_project](../../project/runbooks/RBK_017_setting_up_a_new_unity_project.md)

**Phase:**

---

## What I Worked On

- Tooling for the Game Design and Development course (Unity + C#): triaging the Unity-related `nixpkgs` list, deciding the package set, and designing the VSCode and Neovim support under the shared-binaries convention.

---

## What Got Done

- Triaged the Unity package list down to `unityhub` plus the VSCode Unity extension; dropped the rest as unrelated.
- Researched Unity on NixOS, the Roslyn language server route for both IDEs, and Unity debugging in Neovim.
- Wrote the `gameDev` module (options, hm entry point, unity, `dotnet`, debug) with the `git-lfs` assertion.
- Wrote the VSCode C# and Unity source files following the two-tier convention.
- Wrote the coresponding Neovim (CypherIDE) RFC (Draft) and the setup and decisions doc.

---

## Key Decisions Made

- Pin Unity 6000.3 LTS; avoid 6000.6+ (NixOS crash, nixpkgs#561247).
- Roslyn LS + csharpier as the shared language tooling across both IDEs; no OmniSharp/Mason.
- Keep the Microsoft Unity extension in VSCode with a comment noting its proprietary status and VSCodium exclusion.
- Enforce `git-lfs` through an assertion.
- Neovim approach delegated and recorded in the RFC (roslyn.nvim + Nix `roslyn-ls` + Unity-side package).

---

## Where I Got Stuck

- The "one shared debugger" convention does not hold: Unity debugs over Mono's soft debugger, netcoredbg covers CoreCLR only.
- Could not confirm the `roslyn-ls` SDK requirement, so the `sdk_9_0` default is a placeholder.

---

## What I Learned

- Unity's editor is imperative by nature; the declarative parts live in the project (`ProjectVersion.txt`, `Packages/manifest.json`).
- `vimPlugins.nvim-unity` in `nixpkgs` is mostly irrelevant to a lazy.nvim-managed config, and the Unity-side package is per project.

---

## Open Questions

- Unverified:
    1. `DOTNET_ROOT` value,
    2. `dotnetAcquisitionExtension.existingDotnetPath` setting name,
    3. CSharpier extension attribute path and binary discovery.
       
- Does 6000.3 LTS run correctly under the `nixpkgs` FHS wrapper?
- Which Unity-side Neovim package (`walcht` vs `apyra`) after a trial?
- Is Unity debugging in Neovim reliable enough, or does it stay in VSCode?
- Whether the C# Dev Kit runtime and debugger issues are fixed on the channel in use.

---

## Next Session

- CypherIDE session using the RFC.

---

<!-- Commit range:
CypherOS: [short hash] → [short hash]
CypherIDE: [short hash] → [short hash]
-->