# Runbook: Bump the pinned `dsh` (DeepSeek Harness) version

**Last verified:** 2026-10-13
**Host:** `cypher-nixos`
**Module:** `src/pkgs/noeta/dsh.nix`
**Trigger:** Reactive: a newer `@deepseek-ai/dsh` release has a fix or feature worth pulling in. The package publishes several times a week, so bump by need, not by release.
**Estimated time:** ~10 minutes, plus a first launch that downloads the dependency tree (several minutes)

---

## When To Use This Runbook

- Use this when the pinned `dshVersion` should move to a newer release, or when a bad release needs rolling back to an older one.
- Do not treat every `npm` publish as a trigger; check what changed first.

---

## Prerequisites

- A working checkout of the repository with `dsh` enabled (`cypher-os.pkgs.noeta.dsh.enable = true`).
- Network access to the `npm` registry.
- `nix` available. `npm` is not assumed to be installed; the commands below borrow it from `nixpkgs`.

---

## Procedure

### Step 1 — Look up the available releases

```bash
nix shell nixpkgs#nodejs_24 -c npm view @deepseek-ai/dsh dist-tags --json
```

**Expected output:** a JSON object of dist-tags. Prefer the `latest` tag; `alpha` and other tags are prereleases. If this fails: check network access, or substitute `nodejs_22` if `nodejs_24` is unavailable on the channel.

---

### Step 2 — Review what changed

Skim the upstream [repository](https://github.com/deepseek-ai/deepseek-harness) for the commits or release notes between the pinned and target versions. Look for a changed `bin` entry, a restructured dependency set, or a new native or sandbox dependency.

**Expected output:** no breaking change that affects current usage. If this fails: if the change is unclear or breaking, stay on the current pin.

---

### Step 3 — Edit the pin

In `src/pkgs/noeta/dsh.nix`, change the single `dshVersion` string to the exact target version (no ranges, no tags).

**Expected output:** a one-line diff.

---

### Step 4 — Rebuild

Apply the change with the usual rebuild workflow for the host.

**Expected output:** a successful build and switch. If this fails: see Troubleshooting.

---

### Step 5 — Warm the cache and check the version

```bash
dsh --version
```

**Expected output:**
- the new version string.
- The first launch of a new version downloads the dependency tree and can take several minutes; later launches take about a second.
- If this fails: see Troubleshooting.

---

### Step 6 — Verify behavior

```bash
dsh --help
dsh web
```

**Expected result:**
- help text prints, and the web UI is reachable on localhost.
- Exercise one sandbox-dependent action to confirm the native helper works.

---

### Step 7 — Commit

Commit the version change with a message naming the old and new versions.

---

## Troubleshooting

### The first launch is very slow

**Expected after any version change:**
- `npx` is fetching and caching roughly 80 packages.
- It should not recur for the same version.

### Registry or network errors, or "no matching version"

Confirm connectivity, and confirm the version exists in the dist-tags or version list from Step 1 and was typed exactly.

### Launch fails or behaves oddly after a bump

Roll back (see below). Then compare the two versions' dependency sets before trying again.

### A corrupted or stale cache

- Remove the `npx` cache (`rm -rf ~/.npm/_npx`) and relaunch.
- This forces a full re-download of every cached `npx` package.

### The native sandbox helper is missing

- The sandbox helper is a platform-specific optional dependency (`node-addon-landlock-run-linux-x64` or `-linux-arm64`).
- Look for it under the `@deepseek-ai` scope inside the `npx` cache (`~/.npm/_npx/*/node_modules/`).
- If it is absent for the current platform, clear the cache and relaunch; if it persists, treat the release as broken and roll back.

---

## Rollback

Set `dshVersion` back to the previous version and rebuild. A previously used version is normally still cached, so it launches quickly.

---

## Related

- ADR: [ADR_028](../decisions/ADR_028_2026_10_13_use_a_pinned_npx_wrapper_for_dsh.md)
- Module doc: [dsh](../../source_docs/src/pkgs/noeta/dsh.md)

---

<!-- METADATA
Created: 2026-10-13
Updated: 2026-10-13
Tested by: Cypher Whisperer
-->