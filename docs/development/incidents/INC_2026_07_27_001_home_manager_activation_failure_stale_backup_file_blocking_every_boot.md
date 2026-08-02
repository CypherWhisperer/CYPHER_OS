# INC-2026-07-27-001: Home Manager Activation Failure — _Stale Backup File Blocking Every Boot_

**ID:** INC_2026_07_27_001
**Date:** 2026-07-27
**Severity:** Medium
**Status:** Resolved
**Reported by:** CypherWhisperer

---

## Summary

The `home-manager-cypher\x2dwhisperer.service` unit — _Home Manager's NixOS-integrated activation service_ — failed on every boot from at least 2026-07-27 through 2026-07-30. 

Because `useUserPackages = true` installs packages through a system-managed profile independent of this unit, package installs kept succeeding while everything else Home Manager manages _(dotfiles, session variables, activation hooks)_ silently stopped propagating, masking the failure as a D2-module-specific bug rather than a stuck activation script.

---

## Timeline

| Time                 | Event                                                                                                                                                                                                                                                               |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-07-27 07:55 EAT | Earliest captured failure of `home-manager-cypher\x2dwhisperer.service` _(found retroactively via `journalctl`)_                                                                                                                                                    |
| 2026-07-28 13:15 EAT | Recurrence — _identical failure signature_                                                                                                                                                                                                                          |
| ~2026-07-30          | Attempted to set up D2 system-wide, in Obsidian (plugin), and VSCode (extension). Binary installed successfully; session variables, Obsidian, and VSCode integration did not propagate despite a clean, error-free build. This is what triggered the investigation. |
| 2026-07-30 08:58 EAT | Third captured recurrence, same failure signature                                                                                                                                                                                                                   |
| 2026-07-31           | Diagnosed via `systemctl status`/`journalctl` against the correctly-escaped unit name; root cause identified as a backup-file clobber on `claude_desktop_config.json`                                                                                               |
| 2026-07-31           | Stale `.hm-bak` file removed; unit restarted successfully. A related but distinct dangling-symlink failure (`~/.config/gtk-4.0/assets`) found and cleared on the standalone `home-manager switch` path                                                              |
| 2026-07-31 16:48 EAT | Post-reboot `systemctl status` confirms `Active: active (exited)`, `status=0/SUCCESS` — incident resolved                                                                                                                                                           |

---

## Impact

- **Components affected:** Home Manager activation _(NixOS-integrated path via `home-manager-cypher\x2dwhisperer.service`),_ standalone `home-manager switch --flake .#cypher-whisperer@cypher-nixos` path, D2 system-wide/Obsidian/VSCode integration, GTK4 asset symlinking
  
- **Data affected:** None — no data loss; only a stale `.hm-bak` backup file and a dangling symlink required cleanup
  
- **Time lost:** Multi-day, at minimum 2026-07-27 through 2026-07-31
  
- **Work affected:** D2 tooling rollout blocked; also explained pre-existing, previously-unattributed GNOME theming inconsistencies

---

## Root Cause

`home-manager.backupFileExtension = "hm-bak"` makes Home Manager rename a conflicting file to `<file>.hm-bak` before linking in the Nix-store-managed version, and refuses to proceed if a `.hm-bak` file for that path already exists — _it will not silently overwrite what may be the only surviving copy of the pre-HM original._

A `.hm-bak` file already existed at `~/.config/Claude/claude_desktop_config.json.hm-bak`. Claude Desktop rewrites `claude_desktop_config.json` at runtime _(window state, MCP server entries),_ which replaced the Nix-managed symlink with a plain mutable file on every use.

Each subsequent HM activation saw a "foreign" file in the way, attempted to back it up again, found the old `.hm-bak` still present, and aborted — _a self-perpetuating failure loop on every boot and every `nixos-rebuild switch`._

---

## Resolution

Removed the stale `~/.config/Claude/claude_desktop_config.json.hm-bak`; restarted `home-manager-cypher\x2dwhisperer.service`, which completed successfully. 

Separately, on the standalone path, cleared a dangling symlink at `~/.config/gtk-4.0/assets` _(leftover from an earlier, garbage-collected HM generation)_ that was blocking the `linkGeneration` activation step.

During the same diagnostic pass, a related divergence was found and fixed: `nixosConfigurations` and `homeConfigurations` were building two independent `pkgs` instances with different overlay lists, which separately caused a `pkgs.claude-desktop` "attribute missing" evaluation error on the standalone path only.

#### MORE DETAILS ON [HOME_MANAGER_ERROR_FIX_&_D2_RESOLUTION](../../../../SESSIONS/_SESSION_DOCUMENTS/HOME_MANAGER_ERROR_FIX_&_D2_RESOLUTION.md)

### Changes Made

| Type    | Reference                                                                                                                                                     | Description                                                                                                                                                                                                    |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ADR     | [ADR_012_2026_07_31](../../project/decisions/ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md) *(overlays/nixpkgs-config SSOT)*       | Centralized overlays and `nixpkgs.config` into `flake/nixpkgs-config.nix`, consumed by both `nixosConfigurations` and `homeConfigurations`, closing the `claude-desktop` divergence found during this incident |
| ADR     | [ADR_013_2026_07_31](../../project/decisions/ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md) *(`flake.nix` modularization)* | Flake outputs split into `flake/` as part of the same remediation pass                                                                                                                                         |
| Runbook | [RBK_003](../../project/runbooks/RBK_003_diagnosing_a_failed_home_manager_nixos-integrated_activation_unit.md)                                                | Diagnosing Failed HM NixOS-integrated activation unit                                                                                                                                                          |

---

## Contributing Factors

- `home-manager.useUserPackages = true` installs packages via a system-managed per-user profile that is populated during system activation independent of whether the HM activation _script_ (this unit) succeeds — so package delivery continuing to work was not evidence that HM had fully applied, and made the failure look scoped to D2 rather than global.
  
- The generated systemd unit is named `home-manager-cypher\x2dwhisperer.service` — systemd automatically escapes the literal hyphen in the username to `\x2d` because `-` is also the structural separator in the `home-manager-<user>.service` naming template. Early diagnostic commands run against the unescaped name _(`home-manager-cypher-whisperer.service`)_ returned "could not be found" / "No entries", which delayed root-cause discovery by a full diagnostic round.
  
- Two independent `pkgs` instantiations existed in the pre-refactor `flake.nix` _(a top-level `let pkgs = ...` feeding standalone `homeConfigurations`, versus a `nixpkgs.overlays` module option feeding `nixosConfigurations`),_ with overlay lists that had already silently drifted out of sync.

---

## Prevention

- `services.home-manager.autoExpire` _(module `modules/home/gc-hm.nix`, imported via `modules/home/default.nix`)_ added to reduce stale-generation buildup generally. Note: 
    - this incident's specific trigger was a stale _backup file_, not a stale _generation_ — autoExpire does not directly prevent recurrence of this exact failure mode, but is adjacent hygiene adopted during the same remediation pass.
- `home-manager.backupCommand` _(e.g. routing through `trash-cli` instead of an in-place `.hm-bak` sibling)_ identified as an alternative that would not be susceptible to this exact stale-backup clobber loop. Not yet adopted — open question, see [journal](../journal/2026_07_31_home_manager_incident_and_flake_modularization.md).
  
- Documented the systemd unit-name escaping behavior so future `systemctl`/`journalctl` invocations against this unit use the correct escaped name _(or the `systemctl --failed` pattern)_ immediately rather than rediscovering it.

---

## Lessons Learned

`useUserPackages` package delivery succeeding independently of the HM activation service is a trap:
- "the rebuild completed and my packages are there" is not evidence that Home Manager fully applied. 
- `systemctl status` on the _(correctly-escaped)_ unit is a more reliable post-rebuild check than generation number or package presence alone.
- Separately: 
    - any flake exposing both a NixOS-module-integrated HM path and a standalone `homeConfigurations` path will silently diverge in `pkgs`/overlays unless the two are explicitly unified at the source — _this is systemic, not a one-off, and is now addressed structurally via the overlays/nixpkgs-config single source of truth._

---

<!-- 
METADATA Opened: 2026-07-27 
Resolved: 2026-07-31 
Related journal entry: [2026_07_31_home_manager_incident_and_flake_modularization](../journal/2026_07_31_home_manager_incident_and_flake_modularization.md) 
-->