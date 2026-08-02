# Incidents

Records of significant failures, unexpected behavior, or production-impacting events during development and operation of CypherOS. Each incident is documented with timeline, root cause analysis, resolution, and lessons.

---

## Index

| Incident                                                                                                          | Date       | Severity | Summary                                                                                            |
| ----------------------------------------------------------------------------------------------------------------- | ---------- | -------- | -------------------------------------------------------------------------------------------------- |
| [INC-2026-04-15-001](INC_2026_04_15_001.md)                                                                       | 2026-04-15 | High     | OOM build crash — `nixos-rebuild switch` on `nixos-unstable`                                       |
| [INC_2026_06_06_001](INC_2026_06_06_001_build_failure_blocks_system_rebuild.md)                                   | 2026-06-06 | High     | `python3.13-pipx-1.8.0` failed its own test suite during the Nix build, preventing system rebuild. |
| [INC_2026_06_12_001](INC_2026_06_12_001_obsidian_EACCESS_crash_on_symlinked_git_repository.md)                    | 2026-06-12 | Medium   | Symlinking CypherOS repository to obsidian resulted into an Obsidian EACCESS crash.                |
| [INC_2026_07_27_001](INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md) | 2026_07_27 | Medium   | Home Manager Activation Error resolution. Stale Backup File Blocking                               |

---

## Severity Levels

|Level|Meaning|
|---|---|
|**Critical**|System unbootable or data loss|
|**High**|Development environment unusable; significant work blocked|
|**Medium**|Degraded functionality; workaround available|
|**Low**|Minor inconvenience; no work blocked|

---

## Template

→ [`docs/templates/incident/INC-YYYY-MM-DD-000-template.md`](../../_templates/incident_template.md)
