# ADR_029_2026_10_13: Drop DSH Desktop until an official build exists or one is genuinely needed

**Date:** 2026-10-13
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

- Several community projects named `dsh-desktop` wrap the DeepSeek Harness web UI in an Electron shell.
- None is published by DeepSeek.
- The repository originally targeted, [`anywhere-labs/dsh-desktop`](https://github.com/anywhere-labs/dsh-desktop), ships installers for Windows (x64) and macOS (universal) only; no Linux build exists.
- Other forks (for example [`liguobao/dsh-desktop`](https://github.com/liguobao/dsh-desktop)) do ship a Linux AppImage but are maintained independently with unknown trust and security practices.

- The official `dsh` CLI already serves the same web UI locally (`dsh web`), see [ADR_028](ADR_028_2026_10_13_use_a_pinned_npx_wrapper_for_dsh.md). An [upstream discussion](https://github.com/deepseek-ai/deepseek-harness/discussions/810) warns that exposing the gateway beyond localhost is unauthenticated, and a GUI shell makes such exposure easier to enable without noticing.

## Decision

- No DSH desktop wrapper is packaged or enabled.
- Revisit when either
    - (a) DeepSeek ships an official desktop build with Linux support, or
    - (b) an unofficial one is stable, adopted by the community, **and genuinely needed**.

## Reasoning

- The browser-based UI from the official CLI covers the same need with nothing third-party in the trust chain.
- The only repository named has no Linux artifact. Building Electron from source in Nix is the hardest packaging class and not justified by a convenience wrapper.
- Unofficial wrappers add an unvetted binary that handles API credentials and local filesystem access.

## Alternatives Considered

### Package a Linux-shipping fork via its AppImage

- Viable with `appimageTools.wrapType2`, since that is a repack and not a source build.

**Rejected for now:**
- the benefit is cosmetic, and the trust cost is real.

### Build the named repository from source

**Rejected:**
- no Linux build target exists, and Electron source builds under Nix are fragile and high-maintenance.

### Run the web UI inside a dev shell

**Rejected:**
- for the reasons given in ADR_028.

## Consequences

**Positive:**

- No unvetted Electron binary in the system closure.
- No packaging or maintenance cost.

**Negative / Trade-offs:**

- No native window or launcher entry for `dsh`; the web UI is used from a browser.

**Neutral / Operational:**

- The `gui.dshDesktop.enable` option and `src/pkgs/noeta/dsh_desktop.nix` currently remain as inert placeholders.
- Any future revisit should re-check Linux support first, then vet the project's handling of credentials and network exposure.