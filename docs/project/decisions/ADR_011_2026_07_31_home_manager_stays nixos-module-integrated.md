# ADR_011_2026_07_31: Home Manager Stays NixOS-Module-Integrated

**Date:** 2026-07-31
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

CypherOS currently wires Home Manager into the system as a NixOS module _(`home-manager.nixosModules.home-manager` in `flake/hosts.nix`),_ so `sudo nixos-rebuild switch` applies both system config and the user's HM config in one command.

The session that produced [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) opened with an explicit goal: understand splitting Home Manager and NixOS into two independently-managed flows — `nixos-rebuild` for system, `home-manager switch` for user config — on the assumption that the combined setup didn't support running them separately, and that this coupling was a source of friction.

During the incident investigation it became clear that assumption was wrong: `flake.nix` already exposed a standalone `homeConfigurations."cypher-whisperer@cypher-nixos"` output, and `home-manager switch --flake .#cypher-whisperer@cypher-nixos` was fully usable independent of `nixos-rebuild` — *it had simply never been exercised, which is also why its `pkgs`/overlay divergence from the NixOS-integrated path had gone unnoticed until this session.*

Separately, the actual boot-time failure driving the desire for a split *(`home-manager-cypher\x2dwhisperer.service` failing every boot)* was root-caused to a stale `.hm-bak` backup file — a bug unrelated to whether HM was module-integrated or standalone, and one that would have existed either way.

## Decision

CypherOS keeps Home Manager NixOS-module-integrated. `nixos-rebuild switch` continues to apply both system and HM config together by default.

The pre-existing standalone `homeConfigurations` path remains available for HM-only changes and is now a first-class, actively-used, actively-tested path rather than a documented-but-unexercised convenience.

This provides a workflow where home manager-related changes can be applied independently _(via `home-manager` command)_ but also exposing a flexibility of applying changes both in NixOS and Home Manager _(via `nixos-rebuild` command)_
## Reasoning

The two things a full split was meant to provide — 
1. the ability to apply HM-only changes without a full `nixos-rebuild`, and 
2. freedom from a shared failure mode where a system rebuild is blocked by an HM activation error — _already exist under the current architecture._

(1) is satisfied by the standalone `homeConfigurations` output. (2) was never actually true in the way assumed: 
- HM activation failures do not fail `nixos-rebuild switch` itself *(the build and generation-switch succeed; only the HM activation **unit** fails, as seen throughout this incident),* so the "shared failure mode" motivating a split was a misdiagnosis of the actual bug, not a structural property of the integrated approach. 
- With the underlying bug fixed, no unmet need remains that a full split would address.

## Alternatives Considered

### Full decoupling — _remove `home-manager.nixosModules.home-manager` from `nixosConfigurations` entirely_

HM would never run as part of `nixos-rebuild switch`; all user-environment changes would require a separate, deliberate `home-manager switch` invocation. 

Rejected:
- this would lose `useGlobalPkgs`/`useUserPackages` integration *(HM packages appearing in `/etc/profiles/per-user`, visible to GDM and other system contexts)* unless manually reconstructed, and would turn every routine change touching both system and user config *(the common case in CypherOS's `modules/apps/*/{hm,system}.nix` split pattern)* into two commands instead of one, for no corresponding benefit once the actual bug was fixed.

### Keep both, but make standalone the default workflow

Same technical shape as the current decision, but with `home-manager switch` treated as primary and `nixos-rebuild` reserved for system-only changes.

Rejected as unnecessary — no evidence during the [session](../../../../SESSIONS/_SESSION_DOCUMENTS/HOME_MANAGER_ERROR_FIX_&_D2_RESOLUTION.md) that the combined default workflow was itself a problem; the friction was entirely attributable to the boot-failure bug.

## Consequences

**Positive:**

- No architectural change required — zero migration risk, zero new failure surface introduced
  
- Standalone `homeConfigurations` path is now confirmed working and available whenever an HM-only change is preferred *(e.g. rapid theming iteration without a full system rebuild)*
  
- The `pkgs`/overlay divergence between the two paths, discovered because the standalone path was finally exercised, is fixed as a direct consequence — see [ADR_012_2026_07_31](ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)

**Negative / Trade-offs:**

- `home-manager.backupFileExtension` _(a NixOS-module-only option)_ and the standalone path's `-b <ext>` CLI flag remain two separate mechanisms for the same behavior — no Nix-level way to unify them; addressed operationally via a zsh alias rather than architecturally
  
- Both paths must continue to be kept in sync manually for anything not already covered by the SSOT *(e.g. any future NixOS-module-only `home-manager.*` option with no standalone equivalent)*

**Neutral / Operational:**

- Going forward, changes to `modules/home/*` should be validated against both `nixos-rebuild switch` and `home-manager switch --flake .#cypher_whisperer@cypher-nixos` where practical, now that both are treated as live paths rather than one being vestigial

---

<!-- NOTES: Superseded username references (cypher-whisperer vs cypher_whisperer) reflect the state at time of writing — see ADR_014 for the rename decision. -->