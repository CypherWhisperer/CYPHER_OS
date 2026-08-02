# ADR_014_2026_07_31: Username String Change — `cypher-whisperer` → `cypher_whisperer`

**Date:** 2026-07-31
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

The Linux username `cypher-whisperer` contains a literal hyphen.

Home Manager's NixOS-module integration generates a systemd unit named `home-manager-<username>.service`, and because `-` is also the structural separator in that naming template, systemd automatically escapes any literal hyphen inside the username segment to `\x2d` in the actual registered unit name — producing `home-manager-cypher\x2dwhisperer.service`. 

This is standard, correct systemd behavior, not a bug, but it is non-obvious:
- during [INC_2026_07_27_001](../../development/incidents/INC_2026_07_27_001_home_manager_activation_failure_stale_backup_file_blocking_every_boot.md), `systemctl status`/`journalctl -u` commands run against the plain hyphenated name returned false negatives *("could not be found" / "No entries"),* costing a diagnostic round before the correctly-escaped name *(found via `systemctl list-unit-files | grep home-manager`)* was used.

The current architecture *(`nix.settings.trusted-users`, `users.users.*`, `home-manager.users.*`, the `homeConfigurations` key, and the AccountsService avatar activation script)* references this username as a literal string in five-plus places across the flake and `modules/`, so a rename touches multiple files but is textual rather than structural.

## Decision

Rename the account and all its literal-string references from `cypher-whisperer` to `cypher_whisperer` (underscore).

**UID (1000) and `home = "/home/cypher-whisperer"` are deliberately kept unchanged** — the home directory path and the username string are decoupled by setting `home` explicitly, so no data under `/home/cypher-whisperer/*` needs to move.

`AccountsService`'s icon/user config files *(keyed on the literal username)* are renamed to match.

## Reasoning

Underscores are not in systemd's unit-name escape set, so `home-manager-cypher_whisperer.service` will register and display as written — no `\x2d`, no gap between what's typed and what's registered, for this or any future systemd-unit-name construction involving the username. 

This directly removes the exact class of diagnostic friction encountered in INC_2026_07_27_001.

Underscore was chosen over alternatives (see below) both for this technical reason and because it matches the project's existing file/note-naming convention (underscores over hyphens).

Keeping the home directory path unchanged, rather than renaming it to match, avoids the only genuinely risky part of a username change:
- NixOS creates a fresh home directory for a new username unless `home` is set explicitly, which would otherwise orphan all existing data under the old path from the new account until manually reconciled. 
- Setting `home` explicitly makes the rename purely textual, with UID continuity *(not username)* being what actually preserves file ownership.

## Alternatives Considered

### `CypherWhisperer` *(mixed case)*

Matches the project's stated developer identity ("Cypher Whisperer" / git remote convention) more closely in appearance. 

Rejected: 
- fights Linux convention *(login names are near-universally lowercase; some tools and scripts assume it),* and does not resolve the systemd escaping issue — mixed-case letters aren't escaped, but this alternative doesn't address the actual technical problem that motivated the rename in the first place.
- `-` vs `_` is the relevant axis, not case.

### Leave the username as `cypher-whisperer`, work around the escaping at the call-site instead

E.g. always reference the unit via `systemctl --failed` / `systemd-escape` rather than typing the name directly.

Rejected:
- this treats a permanent, recurring diagnostic friction as something to route around indefinitely rather than removing at the source, for a one-time, low-risk textual rename.

### Rename both the username and the home directory to match (`/home/cypher_whisperer`)

Fully consistent naming, no lingering `cypher-whisperer` reference anywhere including the filesystem. 

Rejected for now:
- this is the actually-risky version of the rename *(directory move, path updates in every place `/home/cypher-whisperer` appears, higher chance of a missed reference breaking something at boot).*
- Deferred as a possible future follow-up once the low-risk textual rename is validated in production; not bundled into this decision.

## Consequences

**Positive:**

- `home-manager-cypher_whisperer.service` is diagnosable with the plain name going forward — no more `\x2d` lookups
- Consistent with the project's established underscore-over-hyphen file-naming convention
- UID/home-directory continuity means the rename carries effectively no data risk

**Negative / Trade-offs:**

- Every literal occurrence of `cypher-whisperer` across `modules/users/`, `hosts/nixos/configuration.nix` *(`trusted-users`),* `flake/hosts.nix`, `flake/home-configurations.nix`, and the AccountsService activation script must be found and updated consistently — a missed reference *(e.g. a stale `home-manager.users.cypher-whisperer` left alongside a new `cypher_whisperer` entry)* would silently create a second, inactive user config rather than erroring clearly
  
- Historical documentation *(prior journal entries, this incident report, earlier ADRs)* correctly continues to reference `cypher-whisperer` for events that occurred under that name — *no retroactive renaming of historical records*

**Neutral / Operational:**

- The home directory remains `/home/cypher-whisperer` on disk indefinitely under this decision; a future ADR would be needed to additionally move it to `/home/cypher_whisperer` if full consistency is later desired
  
- Validated the same way as the INC_001 fix: `nixos-rebuild boot --install-bootloader`, reboot, confirm login and `systemctl status home-manager-cypher_whisperer.service`, before treating the rename as complete

---