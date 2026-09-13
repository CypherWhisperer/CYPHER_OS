# DevOps Aggregator — `system.nix`

> Pure import router for the entire `modules/devops/` subtree. Pulls every devops submodule into the NixOS evaluation context and nothing else.

**Module path:** `modules/devops/system.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Import `../profile/options.nix` so profile-driven defaults are visible to all devops submodules at NixOS evaluation time
- Import `./options.nix` so the `cypher-os.devops.*` option namespace is declared before any submodule references it
- Import every devops submodule file, making their `config` contributions visible to the NixOS module system

**Does not:**

- Declare any options — those live in `options.nix`
- Set any `config` values — those live in the individual submodule files
- Contain any package lists, service declarations, or user modifications

---

## Evaluation Context

| Property              | Value                                                                   |
| --------------------- | ----------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                          |
| Options namespace     | None — this file declares no options                                    |
| Imports `options.nix` | Yes — required; NixOS-context modules cannot see HM-context option declarations without it |
| Kill-switch guard     | None — this file is a pure router; guards live in each submodule        |
| Profile default       | N/A                                                                     |

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** The single `imports` list that constitutes the entire content of this file.

**What does it do?** Merges every listed file into the NixOS module system evaluation. After this import, all `cypher-os.devops.*` options are declared, all service configurations are registered, and all `environment.systemPackages` contributions are visible for merging.

**Why is it here?** The CypherOS architecture separates option declaration from configuration to avoid split-brain evaluation errors: a NixOS-context module cannot reference a `cypher-os.*` option that was declared only in the HM context. By importing `../profile/options.nix` and `./options.nix` explicitly and unconditionally here, every submodule that follows is guaranteed to see the full option namespace during evaluation.

The pattern — one aggregator file with only imports, no config — keeps the entry point clean and makes the full scope of the devops subtree visible at a glance. Adding a new submodule is a single-line change here plus the new file; nothing else needs to know about it.

```nix
imports = [
    ../profile/options.nix
    ./options.nix
    ./containers.nix
    ./kubernetes.nix
    ./databases.nix
    ./iac.nix
    ./secrets.nix
    ./n8n-contained.nix
    ./cloud.nix
    ./observability.nix
    ./networking.nix
    ./cicd.nix
];
```

---

## Dependencies

**Imported files:**
- `../profile/options.nix` — exposes profile-driven defaults (`cypher-os.profile.*`) to NixOS-context modules; without this, submodules that reference profile options would fail at evaluation
- `./options.nix` — declares the full `cypher-os.devops.*` namespace; must precede any submodule that references those options
- All submodule files — each contributes independently; removing one from this list disables it entirely

**NixOS options set by this file:** None

**nixpkgs packages required:** None

**External flake inputs used:** None

---

## Option Surface

This file reads no options and declares no options. It is a pure structural file.

---

## Design Notes

- The ordering within `imports` is not significant for correctness — NixOS merges all modules simultaneously. The ordering here is by conceptual layer: shared context first (`profile/options.nix`, `options.nix`), then submodules in rough dependency order (containers before kubernetes, since k3d/kind depend on Docker).

---

## Known Limitations

- There is no automated check that a newly created submodule file has been added to this imports list. If you create `modules/devops/foo.nix` and forget to add it here, it is silently ignored. The post-rebuild verification runbook includes a step to catch this.

---

## Related

| Type                | Reference                        |
| ------------------- | -------------------------------- |
| Options declared in | `./options.nix`                  |
| Imported by         | `hosts/nixos/configuration.nix`  |
| Profile defaults    | `modules/profile/system.nix`     |
