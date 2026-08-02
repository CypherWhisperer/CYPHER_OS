# INC_2026_06_12_001: Obsidian EACCES Crash on Symlinked Git Repository

**ID:** INC_2026_06_12_001
**Date:** 2026-06-12
**Severity:** Medium
**Status:** Resolved
**Reported by:** CypherWhisperer

---

## Summary

Obsidian crashed at startup with `EACCES: permission denied, watch` after a symlink to the CypherOS git repository root was placed inside the vault. 

The crash occurred because Obsidian's file watcher followed the symlink and attempted to place inotify watches on `.git/objects/pack/` files, which git intentionally stores with read-only permissions _(mode 444)_.

The vault became unloadable — _Obsidian reproduced the crash on every subsequent startup attempt before the symlink was removed._

![](assets/Pasted%20image%2020260613105746.png)


---

## Timeline

| Time                | Event                                                                                                                                                                                            |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-06-12 ~morning | `ln -sf ~/DATA/FILES/PROJECTS/PUBLIC/PERSONAL/LINUX/LINUX_PROJECTS/CYPHER_OS ./CYPHER_OS` executed from within vault's `THE_CHAMBER_OF_SECRETS/COMP_SCIENCE/PROGRAMMING/PROJECTS_DOCUMENTATION/` |
| 2026-06-12 ~morning | Obsidian picked up the symlinked directory tree; `.md` files were visible in the file explorer                                                                                                   |
| 2026-06-12 ~morning | Navigating to `.md` files produced no content; Obsidian froze                                                                                                                                    |
| 2026-06-12 ~morning | Obsidian closed and relaunched in attempt to recover                                                                                                                                             |
| 2026-06-12 ~morning | Startup crash: `EACCES: permission denied, watch '...MY_OBSIDIAN_NOTES/THE_CHAMBER_OF_SECRETS/COMP_SCIENCE/PROGRAMMING/PROJECTS_DOCUMENTATION/CYPHER_OS/res...'`                                 |
| 2026-06-12 ~morning | Root cause identified: inotify watch attempted on `.git/objects/pack/` files (mode 444)                                                                                                          |
| 2026-06-12 ~morning | Offending symlink removed; Obsidian recovered                                                                                                                                                    |
| 2026-06-12 ~morning | `userIgnoreFilters` added to `obsidian.nix`; CypherOS rebuilt; symlink re-created; validated                                                                                                     |

---

## Impact

- **Components affected:** `programs.obsidian` _(Home Manager)_; Obsidian vault `MY_OBSIDIAN_NOTES`; `modules/apps/productivity/obsidian.nix`
- **Data affected:** None — _no vault notes were modified or lost; the `.obsidian/` directory is HM-managed and was unaffected; the CypherOS repository was unaffected_
- **Time lost:** ~30 minutes _(diagnosis, fix, rebuild, validation)_
- **Work affected:** Vault was completely inaccessible between the crash and symlink removal; no in-progress work was lost

---

## Root Cause

- `followSymlinks = true` in `programs.obsidian.defaultSettings.app` instructs Obsidian's Electron file watcher to traverse symlinks during vault directory traversal at startup. 
    - The vault contained a symlink to the CypherOS repository root. The traversal descended into `.git/`, then into `.git/objects/pack/`, where git stores packfiles (`.pack` and `.idx` files).

- Git's garbage collector (`git gc`) and repacker (`git repack`) intentionally set these files to mode 444 _(read-only for owner, group, and other)_ to protect object integrity — this is standard git behaviour, not a NixOS misconfiguration or permissions anomaly. 
    - Node.js's `fs.watch()` _(the underlying inotify interface used by Electron)_ requires read permission on a path to register a watch.
    - Attempting to watch a mode-444 file as a non-root user raises `EACCES`.
    - Obsidian treated this as a fatal error and crashed.

- Because Obsidian attempts to re-establish the same watch setup on every startup _(the vault path is persisted in `~/.config/obsidian/obsidian.json`)_, the crash reproduced on every subsequent launch — _making the vault completely inaccessible until the symlink was removed._

---

## Resolution

Two-part fix:

1. **Immediate:** Removed the offending symlink to unblock vault access.

```bash
rm ~/DATA/FILES/PROJECTS/PRIVATE/PERSONAL/MY_OBSIDIAN_NOTES/THE_CHAMBER_OF_SECRETS/COMP_SCIENCE/PROGRAMMING/PROJECTS_DOCUMENTATION/CYPHER_OS
```

2. **Permanent:** Added `userIgnoreFilters` to `programs.obsidian.defaultSettings.app` in `modules/apps/productivity/obsidian.nix`. This key is read during vault traversal at startup — _before watch registration_ — and causes Obsidian to skip both indexing and inotify watch setup for any directory whose name matches a filter entry. 
    - `.git` was the immediate fix; the list was extended to cover all development ecosystems likely to be encountered across current and future work.
    
    - After rebuilding and re-creating the symlink, Obsidian started cleanly, the CypherOS directory tree was visible and navigable, `.md` files loaded correctly, and edits propagated to the repository in real time.

### Changes Made

| Type    | Reference                                                                                                                               | Description                                                                      |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Config  | `modules/apps/productivity/obsidian.nix`                                                                                                | Added `userIgnoreFilters` to `defaultSettings.app`                               |
| Doc     | [`obsidian.md`](../../source_docs/modules/apps/productivity/obsidian.md)                                                                       | Updated `app` settings table; added design decision and known limitation entries |
| Journal | [`2026_06_12_obsidian_symlink_integration...`](../journal/2026_06_12_obsidian_symlink_integration_and_file_watcher_crash_resolution.md) | Session journal entry                                                            |

---

## Contributing Factors

- `followSymlinks = true` was added to `obsidian.nix` without a corresponding exclusion list for filesystem paths that are not safe to watch — _the two settings are interdependent but were not treated as a pair at the time of initial declaration._
- Git's 444 pack object permissions are not widely documented as a file watcher hazard; the failure mode is non-obvious until encountered.
- Obsidian's error screen truncates the offending path, making the exact file responsible for the crash non-immediately identifiable from the UI alone.

---

## Prevention

- `followSymlinks = true` and `userIgnoreFilters` are now treated as a mandatory pair in `obsidian.nix`. The filter list is documented with per-entry rationale. Any future addition of `followSymlinks` to a similar configuration must include a corresponding exclusion list.
- The `userIgnoreFilters` list is scoped broadly _(all common development ecosystems)_ rather than minimally, so that adding new repository symlinks to the vault does not require revisiting the filter list.
- Future symlinks into the vault should target repository roots — _not individual subdirectories_ — with the exclusion list as the safety layer. This is now the established convention.

---

## Lessons Learned

1. `followSymlinks` without `userIgnoreFilters` is an incomplete configuration when the vault contains or may ever contain symlinks into git repositories or project directories.
    - The two options are not independent: enabling symlink traversal without scoping what gets traversed is equivalent to giving Obsidian unrestricted filesystem access from the vault root outward.
    - The exclusion list is not a nice-to-have — _it is the required complement to `followSymlinks = true`, and the two should always be declared together with explicit rationale for each filter entry._

---

<!-- METADATA
Opened: 2026-06-12
Resolved: 2026-06-12
Related journal entry: [2026_06_12_obsidian_symlink_integration_and_file_watcher_crash_resolution](../journal/2026_06_12_obsidian_symlink_integration_and_file_watcher_crash_resolution.md)
-->