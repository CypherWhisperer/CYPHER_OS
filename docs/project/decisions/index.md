# Architecture Decision Records

ADRs document significant decisions made during the design and development of CypherOS — what was decided, why, what alternatives were considered, and what the consequences are.

Each ADR is a permanent record. Once accepted, an ADR is not deleted — it may be superseded by a later ADR, which references it.

---

## Index

| ADR                                                                                              | Date       | Status   | Decision                                                                                                                           |
| ------------------------------------------------------------------------------------------------ | ---------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [ADR-001](ADR_001_cypher-os_namespace_design.md)                                                 | 2026-04-15 | Accepted | `cypher-os` Namespace Design                                                                                                       |
| [ADR-002](ADR_002_gnome_module_isolation.md)                                                     | 2026-04-15 | Accepted | GNOME Module Isolation                                                                                                             |
| [ADR-003](ADR_003_swap_activation.md)                                                            | 2026-04-15 | Accepted | Swap Activation                                                                                                                    |
| [ADR-004](ADR_004_zram_setup.md)                                                                 | 2026-04-15 | Accepted | ZRAM Setup                                                                                                                         |
| [ADR-005](ADR_005_module_architecture.md)                                                        | 2026-04-16 | Accepted | Module Architecture — Three-File Split Convention                                                                                  |
| [ADR-006](ADR_006_global_theming_via_catppuccin_nix.md)                                          | 2026-06-06 | Accepted | Centralized and Global Theme Management via catppuccin/nix                                                                         |
| [ADR-007](ADR_007_2026_06_17_five_browser_fleet_architecture.md)                                 | 2026-06-17 | Accepted | Extended CypherOS' browser namespace to a five fleet configuration each with own purpose and hardening based on assigned use-case. |
| [ADR-008](ADR_008_2026_06_17_brave_configuration_two%20plane_split.md)                           | 2026-06-17 | Accepted | Brave HM and NixOS modules each handling HM and System concernds accordingly.                                                      |
| [ADR-009](ADR_009_2026_06_16_fausto_korpsvart_gtk_theme_source.md)                               | 2026-06-16 | Accepted | Leveragig Fausto_Korpsvart Catppuccin gtk theme configuration for CypherOS                                                         |
| [ADR-010](ADR_010_2026_06_16_programs_module_ownership_for_catppuccin_nix.md)                    | 2026-06-16 | Accepted | use os `programs.*` for supported packages for HM to propagate catppuccin theme from catppuccin/nix                                |
| [ADR_011](ADR_011_2026_07_31_home_manager_stays%20nixos-module-integrated.md)                    | 2026_07_31 | Accepted | Home Manager Stays NixOS-Module-Integrated                                                                                         |
| [ADR_012](ADR_012_2026_07_31_overlays_and_nixpkgs.config_single_source_of_truth.md)              | 2026_07_31 | Accepted | Overlays and `nixpkgs.config` — _Single Source of Truth_                                                                           |
| [ADR_013](ADR_013_2026_07_31_flake.nix_modularization_into_standalone_'flake'_directory.md)      | 2026_07_31 | Accepted | `flake.nix` Modularization into `flake/`                                                                                           |
| [ADR_014](ADR_014_2026_07_31_username_string_change_'cypher-whisperer'_to_'cypher_whisperer'.md) | 2026_07_31 | Accepted | Username String Change — `cypher-whisperer` → `cypher_whisperer`                                                                   |
| [ADR_015](ADR_015_2026_08_15_dropping_garnix_as_a_binary_cache_substituter.md)                   | 2026_08_15 | Accepted | Dropping Garnix as a binary cache substitutor.                                                                                     |
| [ADR_016](ADR_016_2026_08_18_dbms_stack_selection.md)                                            | 2026_08_18 | Accepted | CypherOS initial Database Management Systems stack.                                                                                |
| [ADR_017](ADR_017_2026_08_18_dbms_subvolume_architecture.md)                                     | 2026_08_18 | Accepted | DBMSs submodule Architecture for persistence data and ease of backup and management.                                               |
| [ADR_018](ADR_018_2026_08_18_provisioning_dormant_dbms_subvolumes_ahead_of_need.md)              | 2026_08_18 | Accepted | Provision Dormant DBMS btrf subvolumes ahead of their use.                                                                         |
| [ADR_019](ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md)                                | 2026_08_18 | Accepted | DBMSs don't run on boot but are started up on-demand *(and temporarily and momentarily during periodic  automated backups.)*       |
| [ADR_020](ADR_020_2026_08_18_dbms_backup_strategy.md)                                            | 2026_08_18 | Accepted | Backup Strategy: automated DBMS-native dumps + BTRFS snapshots *(currently manual.)*                                               |
| [ADR_021](ADR_021_2026_08_21_nix_managed_go_tooling_shared_across_editors.md)                    | 2026_08_21 | Accepted | Nix Manages tooling and IDEs simply leverage from that, rather than each diverging with it's own management.                       |
| [ADR_022](ADR_022_2026_08_21_lsp_settings_flat_key_convention)                                   | 2026_08_21 | Accepted | LSP settings' configuration use a flat-key *(over dotted)* as a ***convention.**                                                   |
| [ADR_023](ADR_023_2026_08_22_cypher-os_namespace_and_profile_redesign.md)                        | 2026_08_22 | Accepted | Redesigning the Namespace tree and Profile management.                                                                             |
| [ADR_024](ADR_024_2026_08_22_cross-context_single_source_of_truth_via_osConfig.md)               | 2026_08_22 | Accepted | The mechanism for a single source of truth for cross context scenarios; `osConfig`                                                 |

---

## Statuses

|Status|Meaning|
|---|---|
|**Proposed**|Under consideration — not yet implemented|
|**Accepted**|Decision made and implemented|
|**Deprecated**|Was accepted; no longer applies to the current system|
|**Superseded**|Replaced by a later ADR (noted in the document)|

---

## Template

→ [`docs/templates/adr/ADR-000-template.md`](../../_templates/adr_template.md)
