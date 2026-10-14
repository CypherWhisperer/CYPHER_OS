# ADR_030_2026_10_13: Run Hermes Agent under Home Manager, with only linger on the system side

**Date:** 2026-10-13
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) ships a flake exporting both a Home Manager module (`homeManagerModules.default`) and a NixOS module (`nixosModules.default`).
- Both expose a `services.hermes-agent` option set, but they are separate module-system evaluations with separate option trees:
    - an assignment in one is invisible to the other, and enabling both yields two independent instances.

- The agent is per-person:
    - credentials, memory, sessions and cron jobs belong to one user, and upstream's documentation positions the Home Manager module as the personal-machine path.
    - The gateway runs as a `systemd --user` unit.
    - Home Manager cannot enable user lingering; without it, systemd stops the user manager at logout and the gateway stops with it.
    - Upstream's module header names `users.users.<name>.linger = true` on NixOS as the remedy, and its checks treat cron dispatch as failing closed without it.
    - This is the only system-level requirement the module documents.

## Decision

- Hermes is configured entirely under Home Manager (`hm.nix`).
- The NixOS side (`system.nix`) holds only `users.users.<username>.linger = true`, gated on the Hermes `enable` and `gateway.enable` options.
- Nothing is duplicated across the two evaluation contexts, and upstream's NixOS module is not imported.

## Reasoning

- One instance, owned by the user, matches how the agent's state is meant to live.
- Duplicating the service declaration in both contexts would create two assignment sites for the same values and a risk of two live instances.
- Keeping linger in its own file, gated on the gateway, makes the feature self-contained:
    - disabling the gateway removes the system-side configuration entirely, leaving nothing orphaned in the namespace tree.

## Alternatives Considered

### NixOS service module with a dedicated service user

The system module supports `user`, `group` and `createUser`, which isolates the agent from a personal account. 

**Rejected for the personal-desktop use case:**
- the agent's state is then detached from the user, and its value as a personal agent depends on acting with that user's context.

### Shared configuration consumed by both evaluations

Define the service shape once as data and apply it in both `hm.nix` and `system.nix`. 

**Rejected:**
- the destinations are different option trees, so two assignments are unavoidable, and nothing requires the system-side instance to exist.

### Imperative `loginctl enable-linger`

Works anywhere, including non-NixOS hosts, but is not declarative or reproducible. Retained only as the method for non-NixOS hosts.

## Consequences

**Positive:**

- One module path, one running instance, minimal system-side surface.
- Follows the repository's `options.nix` / `defaults.nix` / `hm.nix` / `system.nix` split without redundant content.

**Negative / Trade-offs:**

- The agent runs with the user's own permissions, so its blast radius is the user account. There is no service-account isolation.
- On non-NixOS hosts, linger must be enabled once by hand (`loginctl enable-linger <user>`).
- The Hermes options must be set in both evaluation contexts, as with other dual-context categories.

**Neutral / Operational:**

- A `gui.enable` sub-branch toggles the desktop application (`programs.hermes-agent.desktop.enable`), defaulted on only for the desktop profile. No official Linux desktop release was found, so it may need to stay off if the package is unavailable on the host.
- Source documentation: [hermes_agent doc](../../source_docs/src/pkgs/noeta/hermes_agent/readme.md). Related: [ADR_031](ADR_031_2026_10_13_keep_hermes_runtime_state_imperative.md).