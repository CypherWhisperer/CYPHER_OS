# Runbook: Diagnosing a Failed Home Manager NixOS-Integrated Activation Unit

<!-- A runbook is a step-by-step operational procedure. It answers: "How do I do X?" for X that happens regularly enough to standardize, or that is critical enough that you cannot afford to improvise. Runbooks are for DOING, not for UNDERSTANDING. Keep them terse. Every step is an action verb. -->

**Last verified:** 2026-07-31 
**Host:** `cypher-nixos` 
**Module:** `flake/hosts.nix` *(Home Manager NixOS-module integration)* 
**Trigger:** Reactive 
**Estimated time:** ~10 minutes
**Session Document:** [2026_07_31_HOME_MANAGER_ERROR_FIX_&_D2_RESOLUTION](../../../../SESSIONS/_SESSION_DOCUMENTS/2026_07_31_HOME_MANAGER_ERROR_FIX_&_D2_RESOLUTION.md)

---

## When To Use This Runbook

Use this whenever a `nixos-rebuild switch` completes and produces a new generation without error, but changes you expected in dotfiles, session variables, dconf settings, or any other Home-Manager-managed part of your environment don't actually show up — especially if package installs (new binaries on `$PATH`) _do_ show up. That combination is the signature of `useUserPackages = true` delivering packages independent of whether the HM activation script itself succeeded.

Do not treat "the rebuild succeeded" or "the package is there" as evidence Home Manager fully applied — check the unit directly.

---

## Prerequisites

- Active shell session on `cypher-nixos` with `sudo` access
- Host uses `home-manager.nixosModules.home-manager` with `useGlobalPkgs`/`useUserPackages` (per `flake/hosts.nix`) — this runbook is specific to that integration, not to standalone `home-manager switch`
- Username as currently configured (post-[ADR_014_2026_07_31](../decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md): `cypher_whisperer`; pre-rename: `cypher-whisperer`)

---

## Procedure

### Step 1 — Find the actual registered unit name

```bash
systemctl list-unit-files | grep home-manager
```

Expected output: a line like `home-manager-cypher_whisperer.service enabled ignored` (or, pre-rename, `home-manager-cypher\x2dwhisperer.service`). 

**Do not assume the unit name matches the plain username string** — systemd escapes any literal `-` inside the username segment to `\x2d`, since `-` is also the structural separator in the `home-manager-<user>.service` naming template.

Copy the name exactly as printed here for every subsequent step; querying an unescaped guess returns false negatives ("could not be found") rather than an error pointing you at the real name.

If this fails: if `grep` returns nothing at all, the unit isn't registered — check that `home-manager.nixosModules.home-manager` is actually imported in `flake/hosts.nix` and that the last `nixos-rebuild switch` succeeded.

---

### Step 2 — Confirm it's actually failing, and get the last exit detail

```bash
systemctl status 'home-manager-cypher_whisperer.service'
```

(Use the exact name from Step 1; single-quote it so your shell doesn't interpret any `\x2d` escape sequence.)

Expected output: if healthy, `Active: active (exited)` with `status=0/SUCCESS`. If failing, `Active: failed (Result: exit-code)` with `status=1/FAILURE` (or similar) and a `Main PID` line — the last few log lines shown inline here are often enough to identify the failure without a separate `journalctl` call.

If this fails / unit not found: fall back to `systemctl --failed` to list every currently-failed unit on the system and confirm the HM unit is among them.

---

### Step 3 — Pull the full activation log

```bash
journalctl -u 'home-manager-cypher_whisperer.service' --no-pager
```

Expected output: one block per boot, each showing the sequence of `Activating <step>` lines HM works through (`checkFilesChanged`, `checkKittyTheme`, `checkLinkTargets`, `writeBoundary`, `installPackages`, `dconfSettings`, `linkGeneration`, file-linking, then any custom activation hooks) up to whichever step it failed at, followed by `Main process exited` / `Failed with result 'exit-code'`.

If this fails (no entries even with the correct name): journald may be volatile-storage-only, discarding logs from prior boots. `systemctl status` (Step 2) still reflects current state regardless; for persistent logs going forward, add `services.journald.storage = "persistent";` to `hosts/nixos/configuration.nix`.

---

### Step 4 — Identify the failure signature

Read the last few lines before `Main process exited` and match against known patterns:

- **`Existing file '...' would be clobbered by backing up '...'`** — a stale backup file (matching `home-manager.backupFileExtension`, e.g. `.hm-bak`) already exists at the target path. See [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) for the full case; resolution is to inspect and remove the stale backup (Step 5).
  
- **`mkdir: cannot create directory '...': File exists` immediately followed by `ln: failed to create symbolic link '...': No such file or directory`** — a dangling symlink at that path (points at a garbage-collected store path). Resolution: `ls -la` the path to confirm it's a broken symlink, then remove it.
  
- **Evaluation error before any `Activating` line appears** (e.g. `attribute '...' missing`) — this is a build/evaluation failure, not an activation failure; it means `nixos-rebuild switch` itself should also have reported a warning at the end (`warning: error(s) occurred while switching to the new configuration`). Check for `pkgs`/overlay divergence between this path and the standalone `home-manager switch` path if the same package works in one context but not the other — see [ADR_012_2026_07_31](../decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md).

---

### Step N — Remediate and verify

For a stale-backup or dangling-symlink signature:

```bash
# stale backup: inspect before removing
diff ~/.config/<path>/<file> ~/.config/<path>/<file>.hm-bak
rm ~/.config/<path>/<file>.hm-bak

# dangling symlink: confirm broken, then remove
ls -la ~/.config/<path>
rm ~/.config/<path>

sudo systemctl restart 'home-manager-cypher_whisperer.service'
systemctl status 'home-manager-cypher_whisperer.service'
```

Expected result: `Active: active (exited)`, `status=0/SUCCESS`. Reboot once to confirm the fix holds at boot time as well, not just on manual restart — re-run Step 2 after reboot.

---

## Troubleshooting

### Fix appears to work, then recurs on a later boot

If the same clobber signature comes back, something outside HM's control (an application rewriting a file HM manages, e.g. a GUI app persisting its own config at runtime) is likely re-creating the conflict on every use. Check whether `force = true` on that specific file option, or switching that entry to unmanaged/seed-once, is more appropriate than repeatedly clearing the backup by hand.

### Package appears installed, but you're still unsure whether HM applied

Don't use package presence as evidence either way — with `useUserPackages = true`, packages land via `/etc/profiles/per-user/<user>` at system-activation time, independent of this unit's success. Only `systemctl status` on the unit itself confirms whether the _rest_ of your HM config (dotfiles, session vars, activation hooks) applied.

### `systemctl status`/`journalctl -u` return "could not be found" / "No entries" even after using this runbook

Re-run Step 1 — the escaped name may differ from what you expect if the username has changed, or if you're on a host/user combination not yet covered by this runbook's assumed naming.

---

## Rollback

This is a diagnostic procedure; there is nothing to "undo" about running it. The remediation steps under Step N are the ones with actual state changes:

- Removing a stale `.hm-bak` file is only reversible if you diffed it first (Step N) — do not skip that check.
- Removing a dangling symlink is safe once confirmed broken via `ls -la`; a real (non-symlink) directory at that path should never be removed without inspecting its contents first.

If remediation makes things worse rather than better, refer to [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) for the specific case this runbook was derived from, or open a new incident record for anything that doesn't match a known signature in Step 4.

---

## Related

- Incident: [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md)
- ADR: [ADR_011_2026_07_31](../decisions/ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md)
- ADR: [ADR_012_2026_07_31](../decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)
- ADR: [ADR_014_2026_07_31](../decisions/ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md)
- Module doc: [flake/hosts](../../source_docs/flake/hosts.md)

---

<!-- METADATA 
Created: 2026-07-31 
Updated: 2026-07-31 
Tested by: Cypher Whisperer 
-->