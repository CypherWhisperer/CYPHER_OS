# `src/pkgs/noeta/dsh.nix`

**Module:** `cypher-os.pkgs.noeta.dsh.enable` **Context:** Home Manager **Last updated:** 2026-10-13

---

## Purpose

- Exposes DeepSeek Harness (`dsh`), an open-source agent harness distributed on npm as [`@deepseek-ai/dsh`](https://www.npmjs.com/package/@deepseek-ai/dsh) ([source](https://github.com/deepseek-ai/deepseek-harness)), as a `dsh` command on `PATH`.

- The module is not a package of `dsh`.
- It installs a small wrapper script built with `writeShellApplication`.
- The wrapper takes Node from the flake-pinned nixpkgs and runs `npx --yes @deepseek-ai/dsh@<dshVersion> "$@"`.
- The version is pinned in one variable, `dshVersion`.
- `npx` fetches the release on first use and caches it under `~/.npm/_npx`.

---

## Key Decisions Made

- **Wrapper over devShell or packaging:**
    - See [ADR_028](../../../../project/decisions/ADR_028_2026_10_13_use_a_pinned_npx_wrapper_for_dsh.md).
- **No desktop wrapper:**
    - See [ADR_029](../../../../project/decisions/ADR_029_2026_10_13_drop_dsh_desktop_until_an_official_build_exists_or_one_is_genuinely_needed.md).
    - `gui.dshDesktop.enable` and `dsh_desktop.nix` remain inert placeholders.
- **Node from the pinned nixpkgs (`nodejs_24`), not `nix shell` at runtime:**
    - Removes the dependence on the flake registry and on invoking `nix` per launch.
    - The published package declares no `engines` field; upstream's monorepo targets `^22.19.0 || >=24.0.0`.
- **Pinned to an exact version, not a range or tag:**
    - Upgrades are deliberate, one-line edits.

---

## Triage

Three candidates were compared; the wrapper was chosen.

|                        | Pinned `npx` wrapper                                 | devShell (devenv + direnv)                                                       | Full Nix packaging                                        |
| ---------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Setup cost             | Minutes                                              | Moderate *(devenv config, `.envrc`, a repository-root assumption)*               | High *(lockfile, hashes, derivation, verification)*       |
| Ceremony at use        | None; ordinary command                               | `direnv allow` once per machine and per `.envrc` change; `devenv up` per session | None; ordinary command                                    |
| Version bump           | Edit one string                                      | Edit one string                                                                  | Regenerate lockfile, recompute hash, rebuild (imperative) |
| Network at use         | Once per new version, then cached                    | Same as wrapper                                                                  | None; fetched at build                                    |
| Supply-chain guarantee | Trusts the npm registry at first run of each version | Same as wrapper                                                                  | Hash-verified, immutable until changed                    |

**Two further options were dismissed:**
- unpinned `npx` *(implicit upgrades)* and `uvx` *(Python only; `dsh` is an npm package).*

- On ceremony alone the wrapper and full packaging tie.
- The deciding factors are setup and maintenance cost against the supply-chain guarantee.
- The package publishes roughly weekly *(about thirty releases between 2026-08-10 and 2026-10-09),* so per-bump lockfile and hash maintenance would be a recurring chore.

### Plan to package, if ever needed

- Revisit packaging when development stabilizes (leaves release-candidate status and the cadence slows), or when hash-verified installs become a requirement. 
- Check `nixpkgs` first; if it packages `dsh` by then, use that.
- Otherwise self-package, following the notes below.

---

## Key Reminders, Warnings and Notes

- **First launch per version is slow:**
    - In a smoke test outside Nix the cold launch took about 130 seconds and a warm launch about one second.
    - Network access is needed once per version.
- **Not bit-for-bit reproducible:**
    - The release pins its own `@deepseek-ai/*` siblings, but some third-party dependencies use semver ranges and no lockfile ships, so transitive resolution can differ between machines or first-run dates.
- **Credentials stay out of Nix:**
    - Provide `DEEPSEEK_API_KEY` (or the relevant provider key) through the environment at runtime.
    - Never place secrets in Nix expressions: they would be copied into the world-readable store.
- **Data leaves the machine:**
    - The DeepSeek API is a hosted cloud service operated by a China-based provider.
    - Avoid sending sensitive code or data; use a local or self-hosted model for that.
- **Keep the web UI on localhost:**
    - An [upstream discussion](https://github.com/deepseek-ai/deepseek-harness/discussions/810) warns that exposing the gateway beyond localhost is unauthenticated.
    - Verify before binding to any other interface.
- **Developer preview:**
    - Upstream warns of breaking changes.
    - Read changes before bumping, and keep rollback in mind.
- **Desktop wrappers:**
    - [`anywhere-labs/dsh-desktop`](https://github.com/anywhere-labs/dsh-desktop) ships Windows and macOS installers only.
    - Forks with Linux AppImages (for example [`liguobao/dsh-desktop`](https://github.com/liguobao/dsh-desktop)) are unofficial and unvetted.
- **Verify the Node attribute.:* 
    - f `nodejs_24` is missing from the pinned channel, `nodejs_22` also satisfies upstream's range.

---

## Operation

Upgrade, roll back or troubleshoot following [RBK_018](../../../../project/runbooks/RBK_018_bump_the_pinned_dsh_version.md).

Verification after a change:
```bash
dsh --version   # prints the pinned version
dsh --help
dsh web         # local web UI, localhost only
```

---

## Reference: Packaging Research

Findings from evaluating the published artifact, kept for a future packaging attempt.

- **Package shape:**
    - `@deepseek-ai/dsh` is small (about 73 KB, 20 files) with `bin` set to `lib/bin.js`.
    - It depends on roughly 80 further packages, mostly sibling `@deepseek-ai/*` packages pinned to the same release.
- **Install behavior:**
    - No install or build scripts run.
    - The one native piece, a Landlock sandbox helper (`@deepseek-ai/node-addon-landlock-run`), ships prebuilt per platform as optional dependencies (`linux-x64`, `linux-arm64`), the same pattern as `esbuild`.
- **Source build not needed:**
    - The monorepo's `engines` and `pnpm@11.7.0` constraints apply only to building from source.
    - Packaging should consume the published npm artifact instead.
- **No lockfile in the tarball:**
    - One must be generated per version, outside the Nix sandbox, with `npm install --package-lock-only` against the published `package.json`, then committed beside the derivation.
    - `prefetch-npm-deps` computes the dependency hash from that lockfile.
- **Hash chain:**
    - A store path is a hash over every input.
    - For `npm`, the lockfile fixes the exact dependency set and fixed-output derivations fetch each tarball against its declared integrity hash, which is why the build can fetch from the network yet stay reproducible.
- **Verify after each lockfile regeneration:**
    - A successful hash and build does not prove the correct platform binary resolved.
    - Run `dsh` and exercise a sandbox-dependent action.
- **Wiring:**
    - `pkgs.callPackage` into `home.packages`, gated on `cfg.enable && cfg.dsh.enable`, replacing the wrapper.