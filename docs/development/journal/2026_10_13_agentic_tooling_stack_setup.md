# 2026_10_13 Agentic Tooling Stack Setup

**Date:** 2026-10-13
**Duration:** ~N hours
**Repos touched:**
1. CypherOS

**Modules touched:**
1. `src/pkgs/noeta/options.nix`
2. `src/pkgs/noeta/claude_code.nix`
3. `src/pkgs/noeta/claude_desktop.nix`
4. `src/pkgs/noeta/ollama.nix`
5. `src/pkgs/noeta/dsh.nix`
6. `src/pkgs/noeta/dsh_desktop.nix` (placeholder, unchanged)
7. `src/pkgs/noeta/gemini_cli.nix`
8. `src/pkgs/noeta/qwen_code.nix`
9. `src/pkgs/noeta/system.nix`
10. `src/pkgs/noeta/hermes_agent/{options,defaults,hm,system}.nix`

**Related Docs:**
1. [ADR_028](../../project/decisions/ADR_028_2026_10_13_use_a_pinned_npx_wrapper_for_dsh.md)
2. [ADR_029](../../project/decisions/ADR_029_2026_10_13_drop_dsh_desktop_until_an_official_build_exists_or_one_is_genuinely_needed.md)
3. [ADR_030](../../project/decisions/ADR_030_2026_10_13_run_hermes_agent_under_home_manager_with_linger_only_system_side.md)
4. [ADR_031](../../project/decisions/ADR_031_2026_10_13_keep_hermes_runtime_state_imperative.md)
5. [RBK_018](../../project/runbooks/RBK_018_bump_the_pinned_dsh_version.md)
6. [dsh doc](../../source_docs/src/pkgs/noeta/dsh.md)
7. [hermes_agent doc](../../source_docs/src/pkgs/noeta/hermes_agent/readme.md)

**Phase:** _TODO_

---

## What I Worked On

- Working out how agentic tooling fits into the `noeta` category.
- First the concepts *(harness, model, agent, skills, computing environment),* what agentic work costs and whether any of it can be free.
- Then the concrete module work:
    - Reviewing the existing `noeta` modules, deciding how to ship DeepSeek Harness (`dsh`), and restructuring Hermes Agent.

---

## What Got Done

- Triaged the Ollama packages; `ollama`, `gollama` and `alpaca` are implemented.
- Chose the pinned-`npx` wrapper for `dsh` and wrote `dsh.nix`
- Dropped `dsh-desktop` for now.
- Restructured Hermes into `hermes_agent/{options,defaults,hm,system}.nix`: everything under Home Manager, with only linger on the system side *(not built yet at time of writing).*

---

## Key Decisions Made

Promoted to ADRs:

- `dsh` as a pinned `npx` wrapper over a devShell or full packaging ([ADR_028](../../project/decisions/ADR_028_2026_10_13_use_a_pinned_npx_wrapper_for_dsh.md).
- No DSH desktop wrapper until an official build exists or one is genuinely needed ([ADR_029](../../project/decisions/ADR_029_2026_10_13_drop_dsh_desktop_until_an_official_build_exists_or_one_is_genuinely_needed.md)).
- Hermes under Home Manager, linger only on the system side ([ADR_030](../../project/decisions/ADR_030_2026_10_13_run_hermes_agent_under_home_manager_with_linger_only_system_side.md)).
- Hermes model default and credentials stay imperative ([ADR_031](../../project/decisions/ADR_031_2026_10_13_keep_hermes_runtime_state_imperative.md)).

Not in an ADR yet:

- Subscription-dependent harnesses are supported behind per-leaf toggles *(set-and-forget: flip a toggle when a subscription starts).*
- `opencode-claude-auth` is not packaged: Anthropic prohibits third-party tools from using a Claude subscription.
- Agent memory stays plain Markdown in git (`AGENTS.md` style) rather than an MCP memory store.

---

## Where I Got Stuck

- Treating a devShell as something a rebuild triggers. It is not: 
    - A devShell is entered with `nix develop` (or by direnv on `cd`), while a rebuild activates a persistent profile.
    - Untangling that is what pushed the decision towards the plain wrapper.

---

## What I Learned

- A harness is the loop around a model *(prompt assembly, tool dispatch, retries);* the same model costs very different amounts under different harnesses because of how much context each resends.
  
- Output tokens cost more than input tokens because decoding is sequential; cached input is far cheaper, so keeping the prompt prefix stable matters.
  
- Chat subscriptions and API access are separate products. First-party CLIs can use a subscription login; third-party tools riding a Claude subscription are prohibited.
  
- Free routes exist:
    - Gemini CLI's free tier, bring-your-own-key harnesses, and local models.
    - Local models do not learn from use; their weights are frozen.
  
- Nix:
    - a store path is a hash over every input.
    - For `npm`, a lockfile is what pins the exact dependency set, and fixed-output derivations are the sanctioned way to fetch it.
    - Published npm tarballs ship no lockfile, so packaging one means generating it imperatively.
  
- Hermes:
    - keys declared in Nix become Nix-owned (merged on every rebuild, refused by the CLI at runtime); undeclared keys stay editable.
    - Secrets in `environment` or path literals end up in the world-readable Nix store.
  
- Home Manager cannot enable linger; without it the user manager stops at logout and takes the gateway with it.

---

## Open Questions

- Keep or remove the inert `gui.dshDesktop.enable` option and `dsh_desktop.nix` placeholder?
- When to adopt sops/age so Hermes credentials can move to `environmentFiles`.
- Whether the Markdown-memory approach and the unfree-by-name allowlist deserve their own ADR or RFC once implemented.

---

## Next Session



---

<!--
Commit range (fill in after session): 
CypherOS: [short hash] → [short hash]
-->