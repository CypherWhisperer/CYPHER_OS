# ADR_031_2026_10_13: Keep Hermes runtime state imperative *(model default and credentials)*

**Date:** 2026-10-13
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

- The Hermes Home Manager module renders a declarative `settings` attribute set into Hermes's own `config.yaml` at activation.
- The merge is selective:
    - keys declared in Nix replace the corresponding keys on disk, and every other key is kept.
- Declared keys become Nix-owned in two ways:
    - a `.managed` marker makes the Hermes CLI refuse to change them at runtime, and the next rebuild re-applies them regardless.
- Undeclared keys stay freely editable through the CLI.

- Credentials follow a similar shape. The module rewrites `~/.hermes/.env` only when `environment` or `environmentFiles` is non-empty.
- Values placed in `environment`, or referenced as Nix path literals, are copied into the Nix store, which every user on the machine can read.
- Only `environmentFiles` given a runtime path string *(for example a secret-manager path)* keeps secrets out of the store.

- The model and provider are still being experimented with, and no secrets-management tooling (sops, age) has been adopted yet.

## Decision

- No Hermes runtime-mutable state is declared in Nix:
    - `settings.model.default` is excluded, and `environment`, `environmentFiles` and `authFile` are not used.
    - The model and credentials are managed imperatively through Hermes itself.
    - A comment block in `hm.nix` records the exclusion and its possible future use.

## Reasoning

- Declaring the default model would lock that one key, forcing a rebuild to switch models, which defeats experimentation.
- Declaring credentials correctly requires a secrets pipeline that does not exist yet; declaring them incorrectly leaks them into the Nix store.
- The lock is scoped per key, so excluding these keys costs nothing for the rest of the configuration.

## Alternatives Considered

### Declare the model through a shared constant

Single source of truth in `cypherOsConstants`, applied to `settings.model.default`. 

**Rejected for now:** it makes the model Nix-owned and non-switchable at runtime. Appropriate later for a host that needs an enforced baseline.

### Supply credentials via `environmentFiles` backed by a secrets manager

The correct declarative approach. 

**Deferred until sops/age (or an equivalent) is adopted and the set of providers in use has settled.**

### Declare credentials in `environment`

**Rejected:** the values would be written to the world-readable Nix store.

## Consequences

**Positive:**

- Models and providers can be switched freely at runtime.
- No secret ever touches the Nix store or the repository.
- No premature secrets infrastructure.

**Negative / Trade-offs:**

- A new machine needs manual provider and model setup; this part of the setup is not reproducible from the repository.
- Credentials live in a plaintext file under `~/.hermes/`, outside version control and outside any encryption layer.

**Neutral / Operational:**

- Revisit the model decision when a host needs an enforced baseline (a CI host, a shared account, or any machine where a fixed model is non-negotiable): declare the key, ideally via a constant.
- Revisit credentials when a secrets manager is adopted: move to `environmentFiles` with a runtime path.
- Related: 
    - ADR: [ADR_030](ADR_030_2026_10_13_run_hermes_agent_under_home_manager_with_linger_only_system_side.md)
    - source documentation: [hermes_agent doc](../../source_docs/src/pkgs/noeta/hermes_agent/readme.md).