# ADR_016_2026_08_18: DBMS Stack Selection

**Date:** 2026-08-18
**Status:** Accepted
**Deciders:** CypherWhisperer

---

## Context

CypherOS needed a defined database stack covering eight functional categories *(primary relational, secondary/compat relational, cache, embedded, search, time-series, graph, document)* rather than picking tools ad hoc per-project.

The goal was a stack sized for solo/small-team development on a single dev machine — *not a production fleet* — while still leaving a clear, low-friction path to scale any individual category up when a real project demands it.

---

## Decision

| Category                  | Chosen                                  | Over                      |
| ------------------------- | --------------------------------------- | ------------------------- |
| Primary relational        | PostgreSQL                              | —                         |
| Secondary / compatibility | MariaDB                                 | MySQL                     |
| Cache                     | Valkey                                  | Redis                     |
| Embedded/lightweight      | SQLite *(DB Browser for SQLite as GUI)* | SQLiteStudio              |
| Search                    | Meilisearch                             | Elasticsearch, OpenSearch |
| Time-series               | TimescaleDB *(Postgres extension)*      | InfluxDB                  |
| Graph                     | Neo4j                                   | —                         |
| Document                  | MongoDB *(`mongodb-ce`)*                | plain `mongodb` package   |

---

## Reasoning

**PostgreSQL (primary):**
- No serious competing candidate was considered for this role — it's the default choice for a general-purpose relational primary given its extension ecosystem *(which is itself the reason TimescaleDB/pgvector/PostGIS ride inside it rather than needing separate daemons).*

**MariaDB over MySQL:**
- GPLv2 throughout with no dual-licensing ambiguity, vs.
- Oracle-owned MySQL gating newer Enterprise features.
- It's the ecosystem default across NixOS/general Linux distros now.
- Concretely:
    - MariaDB gets `secureSuperUserByDefault`-equivalent behavior *(socket-auth root)* for free, where MySQL needs the module to actively patch it in.

**Valkey over Redis:**
- Redis Ltd. relicensed away from BSD in March 2024 *(RSAL/SSPL, non-OSI).*
- The Linux Foundation forked the last BSD release as Valkey, backed by AWS/Google Cloud/Oracle.
- Valkey is now the default Redis-protocol implementation on Ubuntu, Debian, Fedora, and AWS ElastiCache.
- Redis later added AGPLv3 as a third license option, but by then Valkey was already the ecosystem default.
- Zero migration cost on NixOS — same `services.redis` module, `services.redis.package = pkgs.valkey;` is the entire swap, since the module resolves the server binary via `cfg.package.serverBin or "redis-server"`.

**SQLite / DB Browser for SQLite:**
- No real alternative considered for the embedded role — *SQLite is the only serious option in this category.*
- DB Browser for SQLite *(`sqlitebrowser`)* picked over SQLiteStudio for being more widely used/actively maintained; no need to run both.

**TimescaleDB over InfluxDB:**
- TimescaleDB is a Postgres _extension_, not a separate engine — no new daemon, no new backup tooling, no new query language *(plain SQL on the DB already running as primary).*
- InfluxDB would only earn its keep for a workload that's purely time-series at high ingest rates where InfluxQL/Flux's purpose-built model matters — *not the case here.*

**Meilisearch over Elasticsearch/OpenSearch:**
- Elasticsearch/OpenSearch are built for log-analytics/enterprise search at a scale far beyond a personal dev machine, and both carry real operational weight *(JVM heap tuning, cluster health, ILM).*
- Meilisearch gets ~90% of *"add search to an app"* use cases with a single static Rust binary and near-zero tuning — *right-sized for solo/small-team dev.*
- If a future project needs log-aggregation at real scale, OpenSearch *(Apache 2.0, no licensing ambiguity)* is the documented fallback over Elasticsearch.

**Neo4j:** No competing candidate considered — *it's the default choice for the graph category at this scale.*

**MongoDB (`mongodb-ce`) over plain `mongodb`:**
- `mongodb-ce` is the actively maintained, license-clean packaging track.
- The plain `mongodb` attribute has historically been the one `nixpkgs` has had to juggle around MongoDB's 2018 SSPL relicensing.

---

## Alternatives Considered

### Running everything as always-on services from day one

Rejected as a stack-wide default — see [ADR_019](ADR_019_2026_08_18_on-demand_dbms_service_lifecycle.md) for the dedicated decision on service lifecycle.

### Elasticsearch as the search engine

**Rejected:**
- appropriate for log-analytics/enterprise search at scale and tight Kibana integration, neither of which is a current need.
- Can be revisited if a project specifically needs that integration.

### InfluxDB as the time-series engine

**Rejected:**
- Given TimescaleDB's zero-new-infrastructure cost as a Postgres extension. 
- To be revisited only if a workload is purely time-series at ingest rates where InfluxQL/Flux's model earns its keep over SQL.

### Running both Redis and Valkey for different use cases

**Rejected:**
- There are no capability Redis has that Valkey lacks for cache/queue roles (the only Redis-exclusive features are proprietary search/vector modules, that are currently (as of writting this) irrelevant).
- Running two overlapping KV stores is pure operational overhead.

---

## Consequences

**Positive:**

- A four-database "foundational" core *(Postgres/MariaDB/Valkey/SQLite)* that covers the vast majority of dev needs with minimal redundancy.
- Zero licensing ambiguity across the entire stack *(GPLv2/BSD-descended/Apache/MIT throughout, no SSPL exposure via `mongodb-ce`).*
- TimescaleDB's extension-not-daemon model keeps the "primary" category doing double duty without adding operational surface area.

**Negative / Trade-offs:**

- Meilisearch is not a drop-in Elasticsearch replacement — no Kibana-equivalent, weaker for genuine ***log-aggregation*** at scale. Accepted given CypherOS' current scope.
  
- Valkey/Redis technical divergence is expected to grow over time *(Valkey pushing multi-threaded I/O; Redis integrating proprietary vector-search into core)* — "drop-in forever" is not guaranteed indefinitely.

**Neutral / Operational:**

- Search/Time-series/Graph/Document categories are installed but not run as persistent services — see [ADR_018](ADR_018_2026_08_18_provisioning_dormant_dbms_subvolumes_ahead_of_need.md).