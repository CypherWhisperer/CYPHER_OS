# Naming Conventions

**Status:** Accepted
**Related:** [ADR_005 — Module Architecture](../../project/decisions/ADR_005_module_architecture.md)

---

## Files and Directories

**Rule: snake_case, always.** Underscores, not hyphens, across every file and directory in the repo — module files, docs, scripts, journal/incident entries. This applies uniformly regardless of what the file contains.
```

security/wireshark.nix # not security/wire-shark.nix  
2026_08_22_profile_redesign.md

````

**Exception — nothing:**
- Even filenames that mirror a Nix attribute path *(which may itself use hyphens, see below)* get written with underscores.
- The file/directory layer and the Nix namespace layer are allowed to diverge in casing, because they're different namespaces with different rules *(see ADR_001's "namespace and file paths are convention-aligned but technically independent" — that separation still holds).*

---
## Nix Option / Attribute Names

**Rule: camelCase for multi-word option names, matching nixpkgs' own module convention** (`enableGhostscriptFonts`, `useGlobalPkgs`) — not snake_case, not kebab-case. Single-word segments (`security`, `privacy`, `fonts`, `enable`) need no casing decision.

```nix
cypher-os.pkgs.editor.vscode.enable
cypher-os.system.fonts.extraFonts.enable    # camelCase, not extra-fonts / extra_fonts
```

**Exception — the `cypher-os` root itself, and any segment that mirrors an upstream package/project name that is itself hyphenated:**
- *e.g. a future `cypher-os.pkgs.editor.nix-vscode-extensions`-style leaf, if a package's own name has a hyphen.*
- Nix identifiers permit hyphens without quoting, so this isn't a syntax workaround — it's a deliberate exception for names that should read as a direct, recognizable mirror of the upstream thing they configure.

**Do not confuse this with Linux usernames:**
- The `cypher-whisperer` → `cypher_whisperer` change (ADR_014) was about systemd unit-name escaping of a *Linux username*, an entirely different namespace with different rules.
- Nix attribute names are unaffected by that constraint — *nothing here should be read as "avoid hyphens everywhere because of the username incident."*

---
## Constants

`cypher-os.constants.<name>` — camelCase, per the option-naming rule above, since constants are options too (`primaryDisk`, `vaultPath`, `homeDirectory`). The generated JSON file mirrors these keys verbatim — no re-casing between the Nix source and the JSON consumed by scripts, so a script reading `.primaryDisk` matches the option name exactly.

---
## Documentation Artifacts *(ADR / RFC / Runbook / Incident / Journal)*

Established pattern, kept as-is:
```

ADR_NNN_YYYY_MM_DD_snake_case_title.md  
RBK_NNN_snake_case_title.md  
INC_YYYY_MM_DD_NNN_snake_case_title.md  
YYYY_MM_DD_snake_case_title.md # journal entries

```

`NNN` is zero-padded to 3 digits, sequential, never reused even if an ADR is superseded *(a superseded ADR keeps its number; the new one gets the next free number — see `templates.md` for the amendment/supersession distinction).* 

Runbooks don't carry a date in the filename the way ADRs do, since a runbook's `Last verified` date lives in its frontmatter and is expected to change over the doc's life — putting a creation date in the filename would go stale in a way that's actively misleading for a "how do I do this *now*" document.

---
## Git Branches

Not yet an established convention in this repo — current a gap rather than assuming one. Worth a line in `git_workflow.md` when that gets filled in, but out of scope for this doc.