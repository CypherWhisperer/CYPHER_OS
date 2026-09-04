# Profile & Lens Default Membership (Reference)

**Status:** Hand-maintained — not enforced by Nix. Ground truth is always
`grep -rn 'cypherOsProfile ==\|cypherOsLens' src/`; treat any drift found
here as a doc bug, not a config bug.
**Last audited:** `<date>`
**Related:** [profile_defaults.md](../contributing/conventions/profile_defaults.md), RBK_015

## Desktop profile

| Option                      | Default | Source file               |
| --------------------------- | ------- | ------------------------- |
| `cypher-os.de.gnome.enable` | `true`  | `src/de/gnome/system.nix` |
| `cypher-os.dm.gdm.enable`   | `true`  | `src/dm/gdm/system.nix`   |
|                             |         |                           |

## Server profile

| Option | Default | Source file |
|---|---|---|

## Both profiles

| Option | Default | Source file |
|---|---|---|

## Lens-conditional (independent of profile)

| Option | Condition | Source file |
|---|---|---|
| `cypher-os.fonts.enable` (full set) | `lens != "nixos"` | `src/fonts/hm.nix` |
