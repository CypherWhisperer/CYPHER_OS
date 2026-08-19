# ADR_018_2026_08_18: Provisioning Dormant DBMS Subvolumes Ahead of Need

**Date:** 2026-08-18
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

Four categories in the stack *(Search/Meilisearch, Document/MongoDB, Graph/Neo4j, plus the Valkey cache)* have no current project driving their use as a running service.

Disk-layout work *(subvolume creation)* requires either a fresh install or a manual retrofit script (see [ADR_017](ADR_017_2026_08_18_dbms_subvolume_architecture.md)) — it is not a pure `nixos-rebuild switch`-time operation.

---

## Decision

Subvolumes, mountpoints, and `tmpfiles.rules` ownership are provisioned **now**, for all six DBMS categories, regardless of whether the corresponding service is currently enabled. Their `services.<db>.enable` blocks remain unset/dormant until an actual project needs them.

---

## Reasoning

The disk-layout portion of onboarding a new DBMS is the part with the highest activation cost *(subvolume creation, retrofit script, ownership wiring)* — provisioning it once, for the whole planned category set, means enabling a dormant DBMS later is a pure Nix-config change *(`services.meilisearch.enable = true;` plus its own option block),* not a disk-touching operation.

This directly avoids re-running retrofit scripting or risking a second live-system disk change each time a new category becomes relevant.

---

## Alternatives Considered

### Provision subvolumes only when a project actually needs the DBMS

**Rejected:**
- This would mean re-running `create_dbms_subvolumes.sh` *(or an equivalent manual step)* against an already-installed, increasingly complex system every time a new category activates, repeating the exact kind of live-system disk operation this session went out of its way to make safe once.
- Provisioning everything in one retrofit pass was judged lower total risk than repeating smaller retrofits over time.

---

## Consequences

**Positive:**

- Enabling Meilisearch/MongoDB/Neo4j/a persistent Valkey later requires zero disk work — *pure `services.<db>.*` configuration.*
- All six subvolumes were created in a single retrofit pass, minimizing the number of times the live system's disk layout was touched.

**Negative / Trade-offs:**

- Four subvolumes currently sit empty/unused, consuming no meaningful space *(Btrfs subvolumes are effectively free until written to)* but adding to the disk-layout surface area to track.
- Provisioning ahead of need is a bet that these four categories will eventually be used — if any of them are dropped from the stack entirely, its subvolume becomes dead weight to clean up.

**Neutral / Operational:**

- See [RBK_006](../runbooks/RBK_006_enabling_a_dormant_dbms.md) for the procedure to actually activate one of these when the time comes.