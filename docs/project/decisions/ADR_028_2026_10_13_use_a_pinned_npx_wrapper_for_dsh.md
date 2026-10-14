# ADR_028_2026_10_13: Expose DeepSeek Harness (dsh) as a pinned `npx` wrapper

**Date:** 2026-10-13
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

- DeepSeek Harness (`dsh`) is an open-source (MIT) agent harness distributed on `npm` as [`@deepseek-ai/dsh`](https://www.npmjs.com/package/@deepseek-ai/dsh).
- It is a developer preview:
    - upstream warns of breaking changes, and the package published roughly thirty releases in about two months (2026-08-10 to 2026-10-09).
    - No Nix package for it was found when this was evaluated.

- Facts about the published artifact that constrain the options:
    - The package itself is small and already bundled, but it depends on roughly 80 further packages, most of them sibling `@deepseek-ai/*` packages pinned to the same release.
    - No lockfile ships in the published tarball.
    - No install or build scripts run on install. The one native piece, a Landlock sandbox helper, ships as prebuilt per-platform optional dependencies (`linux-x64`, `linux-arm64`).
    - The published package declares no `engines` field. The upstream monorepo targets Node `^22.19.0 || >=24.0.0` and builds with `pnpm@11.7.0`; that only matters when building from source.

> **The requirement is a `dsh` command that is available after a normal rebuild, works on a fresh machine without machine-specific paths, and carries as little ceremony as possible, without a maintenance burden that outpaces the release cadence.**

## Decision

- `dsh` is exposed through Home Manager as a thin wrapper script (`writeShellApplication`) that runs `npx --yes @deepseek-ai/dsh@<pinned version>`, with Node supplied from the flake-pinned `nixpkgs`.
- The pinned version lives in one variable, `dshVersion`, in `src/pkgs/noeta/dsh.nix`.

## Reasoning

- **No execution ceremony:**
    - After a rebuild, `dsh` is an ordinary command.
    - There is no `nix develop`, no `direnv allow`, and no process to start by hand.
- **No path assumptions:**
    - Node comes from the pinned `nixpkgs` through `runtimeInputs`, so nothing depends on where the repository is checked out or on the flake registry.
- **Cheap upgrades:**
    - A bump is a one-line edit of `dshVersion`.
    - At the observed release cadence, any approach that regenerates a lockfile and hash per bump becomes a recurring chore.
- **Acceptable launch cost:**
    - In a smoke test outside Nix, the first launch of a version took about 130 seconds (fetching the dependency tree) and later launches about one second, because `npx` caches the package under `~/.npm/_npx`.

## Alternatives Considered

### `devShell` with `devenv` and `direnv`

- A dev shell defining Node and a `dsh web` process.
- Rejected:
    - It needs a directory for `direnv` to anchor to (and therefore a repository-root assumption on every machine), `direnv`'s trust prompt (`direnv allow`) on first use and whenever `.envrc` changes, and explicit `devenv up` or `devenv processes up -d` invocations.
    - Its one real advantage, a managed background process, is not needed.

### Full Nix packaging (`buildNpmPackage`)

- Package the published npm artifact.
- Deferred, not rejected.
- **Benefits:**
    - hash-verified inputs, no network at use time, and an immutable result until deliberately changed.
- **Costs:**
    - no lockfile ships upstream, so one must be generated per version with `npm install --package-lock-only` (inherently imperative), the dependency hash recomputed with `prefetch-npm-deps`, and the platform-specific native optional dependency re-verified each time.
- At roughly weekly releases this is a recurring chore.

### Unpinned `npx`

**Rejected:** it checks the registry on every launch and upgrades implicitly, so behavior can change without any change in the repository.

### `uvx` or `pipx`

**Not applicable:** 
- they run Python packages from PyPI, and `dsh` is an npm package. 
- The PyPI packages named `dsh` and `deepseek-harness` are unrelated projects.

## Consequences

**Positive:**

- A working `dsh` command today with almost no setup.
- Upgrades and rollbacks are one-line edits.
- No lockfile or hash to maintain.

**Negative / Trade-offs:**

- Not bit-for-bit reproducible. The release pins its own `@deepseek-ai/*` siblings, but some third-party dependencies use semver ranges and no lockfile ships, so transitive resolution can differ between machines or first-run dates.
- Trusts the `npm` registry at first run of each version rather than a hash-verified store path.
- Requires network once per version, and the first launch is slow.

**Neutral / Operational:**

- Upgrade procedure: [RBK_018](../runbooks/RBK_018_bump_the_pinned_dsh_version.md).
- Revisit packaging when development stabilizes (leaves release-candidate status and the cadence slows) or when hash-verified installs become a requirement. Check `nixpkgs` first: if it packages `dsh` by then, use that; otherwise self-package.
- Source documentation: [dsh](../../source_docs/src/pkgs/noeta/dsh.md).