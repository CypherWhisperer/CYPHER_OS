# Databases — `databases.nix`

> Configures PostgreSQL and Redis as local development services, and installs the full database toolchain: CLI clients, GUI tools, SQLite, MongoDB utilities, and ClickHouse.

**Module path:** `modules/devops/databases.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-29`

---

## Responsibility

**Does:**

- Enable and configure `services.postgresql` (PostgreSQL 16) with TCP access, dev-friendly auth rules, and a declarative `cypher_dev` database and user
- Enable and configure `services.redis.servers.dev` on the default port with persistence
- Install CLI clients, GUI tools, and database-adjacent tooling as system packages

**Does not:**

- Manage database data directories — handled by their respective NixOS service modules under `/var/lib/postgresql` and `/var/lib/redis`
- Manage application schemas or migrations — those live in project repositories
- Store production credentials — credentials are managed via sops-nix (see `secrets.nix`)
- Run a MongoDB server daemon — excluded due to SSPL licensing issues in nixpkgs; Docker is the recommended alternative

---

## Evaluation Context

| Property              | Value                                                              |
| --------------------- | ------------------------------------------------------------------ |
| Evaluated by          | `nixosModules`                                                     |
| Options namespace     | `cypher-os.devops.databases.*`                                     |
| Imports `options.nix` | No — imported by `system.nix`                                      |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.databases.enable)` |
| Profile default       | `lib.mkDefault true` — enabled by default in the devops profile    |

---

## Block Analysis

---

### Block 1 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents all service configuration and package installation if either `devops.enable` or `devops.databases.enable` is false.

**Why is it here?** Standard CypherOS pattern. Database daemons (PostgreSQL, Redis) are heavyweight persistent services — they should be cleanly disableable on machines or in contexts where local database services are not needed.

---

### Block 2 — `services.postgresql`

**What is this?** NixOS `services.postgresql` module configuration.

**What does it do?** Starts a PostgreSQL 16 server as a systemd service. Enables TCP connections (not just Unix socket). Applies a `pg_hba.conf` that allows the `postgres` superuser to connect without a password (local trust), all local connections with MD5, and all TCP connections from localhost with MD5. Configures connection logging and a 256 MB shared buffer for dev use. Declaratively creates the `cypher_dev` database and a `cypher_dev` user with ownership of that database. _NOTE: The NixOS postgresql module manages: The PostgreSQL data directory (/var/lib/postgresql/<version>/), The postgres system user and group, The systemd service unit, Initial database cluster creation (initdb)._

**Why is it here?** PostgreSQL (the most capable open-source Relational DBMS) is the standard database for most projects I'll work on (Prisma-based Next.js apps, Django projects, etc.). Running it locally avoids the latency and cost of a cloud database during development and allows offline work.

**Key design decisions:**

`package = pkgs.postgresql_16`: pinned to a specific major version. PostgreSQL requires a manual upgrade process (`pg_upgrade`) between major versions — nixpkgs cannot automatically migrate your data when you bump the version. Pinning makes upgrades explicit and deliberate.

`enableTCPIP = true`: allow connections over TCP (127.0.0.1), not just the Unix socket. Required for ORMs (Prisma, SQLAlchemy, GORM), GUI clients (DBGate), and the improved CLI clients (pgcli) to connect. Unix socket connections alone are too restrictive for modern tooling.

`authentication`: the `mkOverride 10` priority overrides the NixOS default `pg_hba.conf` entirely. The rules allow passwordless access for the `postgres` system user (needed by NixOS service management) and MD5 for all other connections. This is a dev-only policy — in any production or staging environment, replace `trust` with `scram-sha-256` and remove the local all all md5 catch-all.

`ensureDatabases` / `ensureUsers`: these are idempotent — safe to leave permanently. The NixOS module creates the database and user on first startup and is a no-op on subsequent starts. Note: `ensureUsers` cannot set passwords (a deliberate security constraint in the NixOS module). Set the password manually once after first activation:

```bash
sudo -u postgres psql -c "ALTER USER cypher_dev WITH PASSWORD 'devpassword';"
```

```nix
services.postgresql = {
  enable      = true;
  package     = pkgs.postgresql_16;
  enableTCPIP = true;
  authentication = pkgs.lib.mkOverride 10 '' ... '';
  settings = { log_connections = true; log_disconnections = true; shared_buffers = "256MB"; };
  ensureDatabases = [ "cypher_dev" ];
  ensureUsers = [{ name = "cypher_dev"; ensureDBOwnership = true; }];
};
```

---

### Block 3 — `services.redis.servers.dev`

**What is this?** NixOS `services.redis.servers.<name>` module configuration for a named Redis instance.

**What does it do?** Starts a Redis (_In-memory data structure store. Upstash Redis usage in Next.js projects can be tested locally against this instance._) instance named `dev` (_NixOS supports multiple named Redis instances: services.redis.servers.<name>. Ports are configurable per instance._) on `127.0.0.1:6379`. Disables authentication (no `requirePass`) for local dev convenience. Configures RDB snapshot persistence at standard intervals. Sets log level to `notice` (low noise, appropriate for dev).

**Why is it here?** Redis is used across many project types: rate limiting, session storage, job queues (BullMQ), Pub/Sub, and as a local stand-in for Upstash Redis in Next.js projects. The NixOS `services.redis.servers.<name>` pattern supports multiple named instances on different ports — the `dev` name is intentional, leaving room for a `test` or `staging` instance later.

`bind = "127.0.0.1"`: Redis has no authentication in this config. Never expose it to the network — binding to localhost is the only protection against accidental exposure.

`port = 6379`: default Redis port. Change if you need multiple instances or have a conflict. Your app's REDIS_URL will be: redis://127.0.0.1:6379

`requirePass` is commented out but left in the source as a reminder. For staging or production-adjacent environments, set it via sops-nix: `requirePassFile = config.sops.secrets.redis_password.path;`

The `save` intervals follow Redis's default recommendation: snapshot after 900s if 1+ keys changed, 300s if 10+, 60s if 10000+. Disable persistence entirely (`save = []`) if you want a clean slate on every restart during testing.

```nix
services.redis.servers.dev = {
  enable = true;
  bind   = "127.0.0.1";
  port   = 6379;
  save   = [ [900 1] [300 10] [60 10000] ];
  settings.loglevel = "notice";
};
```

---

### Block 4 — `environment.systemPackages`

**What is this?** The full package list for database tooling.

**What does it do?** Installs CLI clients, GUI tools, and analytical database tooling. Documents the MongoDB server exclusion.

#### Package inventory

**PostgreSQL tooling:**
- `pgcli` — PostgreSQL CLI with autocomplete, syntax highlighting, and multi-line editing; replaces bare `psql` for interactive sessions; connects with `pgcli -U cypher_dev cypher_dev`
- `pgvector` — PostgreSQL extension for vector similarity search; required for AI/ML workloads that store embeddings alongside relational data; installed as a package but must be enabled per-database (`CREATE EXTENSION vector;`).
> **NOTE: `bg-vector`, as of writing this (2026-05-28) is not in the nixpkgs**

**SQLite:**
- `sqlite` — the SQLite CLI (`sqlite3`) and shared library; no daemon — SQLite is file-based; the library is linked by many applications without a separate install
- `litecli` — SQLite CLI with autocomplete and syntax highlighting; the quality-of-life equivalent of pgcli for SQLite

**Redis tooling:**
- `redis` — installs `redis-cli`; the Redis server is declared above as a service; the CLI is used for interactive inspection (`redis-cli ping`, `redis-cli monitor`, `redis-cli --scan`)

**Universal SQL client:**
- `usql` — single CLI for PostgreSQL, MySQL, SQLite, and more with consistent syntax; useful for polyglot projects where switching tools per-database is friction

**MongoDB CLI tools:**
- `mongodb-tools` — official MongoDB utilities: `mongodump`, `mongorestore`, `mongoexport`, `mongoimport`, `mongostat`, `mongotop`; essential for backup, migration, and data inspection even when the server runs in Docker
- `mongodb-atlas-cli` — CLI for MongoDB Atlas (the cloud offering); manages clusters, users, backups, and data from the terminal

**ClickHouse:**
- `clickhouse` — installs `clickhouse-client` CLI only; ClickHouse is a column-oriented OLAP database; extremely fast for analytical queries over large datasets; used in observability stacks, data engineering pipelines, and anywhere PostgreSQL would be too slow for read-heavy analytics; the server is heavy and best run via Docker (`docker run -d -p 8123:8123 clickhouse/clickhouse-server`)

**GUI clients:**
- `dbgate` — universal open-source DB GUI; supports PostgreSQL, MySQL, SQLite, MongoDB, Redis in one application; the recommended daily-driver for multi-database work
- `mongodb-compass` — official MongoDB GUI; better MongoDB-specific features than DBGate (schema visualisation, explain plans, aggregation pipeline builder); use for deep MongoDB investigation

**DEFERRED:**
- `mongodb` - MongoDB server (mongod) is not declared as a service here. Reason: mongod on NixOS has had packaging inconsistencies, and MongoDB's licensing (SSPL) makes nixpkgs inclusion complicated. For local MongoDB dev, prefer:
    1. A Docker container: docker run -d -p 27017:27017 mongo:latest
    2. MongoDB Atlas free tier (cloud, no local setup)
    3. When the nixpkgs package stabilizes, add services.mongodb here.

##### FIRST-TIME SETUP:
PostgreSQL and Redis need system services (daemons). SQLite is just a library — no service.
```bash

# (PostgreSQL):
# After nixos-rebuild switch, create your dev superuser:
sudo -u postgres psql
#  CREATE USER cypher_dev WITH SUPERUSER PASSWORD 'devpassword';
#  CREATE DATABASE cypher_dev OWNER cypher_dev;
#  \q
# Then connect:
psql -U cypher_dev -d cypher_dev
pgcli -U cypher_dev cypher_dev #  (nicer alternative)

# (Redis):
#   Redis starts automatically. No auth in dev
redis-cli ping   → PONG
```

##### VERIFYING SETUP:
```bash

systemctl status postgresql
systemctl status redis
psql --version
redis-cli --version
sqlite3 --version
pgcli --version
```

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `services.postgresql.*`
- `services.redis.servers.dev.*`
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.pgcli`, `pkgs.pgvector`
- `pkgs.sqlite`, `pkgs.litecli`
- `pkgs.redis`, `pkgs.usql`
- `pkgs.mongodb-tools`, `pkgs.mongodb-atlas-cli`
- `pkgs.clickhouse`
- `pkgs.dbgate`, `pkgs.mongodb-compass`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.databases.enable` | `bool` | `true` (profile default) | Starts PostgreSQL + Redis; installs full toolchain |

---

## Design Notes

- `ensureUsers` cannot set passwords in the NixOS module — this is a deliberate upstream security decision. The password must be set manually once after first activation. The first-time setup procedure is documented in the runbook.
- The MongoDB server (`mongod`) is EXCLUDED, not DEFERRED. MongoDB's SSPL (Server Side Public License) makes nixpkgs inclusion legally complex and the packaging has historically been unreliable. Docker is the correct deployment target: `docker run -d -p 27017:27017 mongo:latest`. The CLI tools (`mongodb-tools`, `mongodb-atlas-cli`) are included because they work against any MongoDB server regardless of how it is running.
- `pgvector` was added in the 2025-05-28 session to support AI/ML workloads. It is a package that provides the extension, not a service; the extension must be activated per-database.
- `clickhouse` installs only the client CLI. The ClickHouse server is a large resource consumer that is better managed ephemerally via Docker when needed for analytics work.

---

## Known Limitations

- `pgcli` connects to PostgreSQL over TCP (requires `enableTCPIP = true`). This is already set, but worth noting if the PostgreSQL config is ever changed.
- The PostgreSQL `shared_buffers = "256MB"` is a dev-machine setting. On a machine with significant RAM being used for Kubernetes or other workloads, this may need tuning. The production recommendation is 25% of total RAM.
- Redis has no authentication in this config. The `bind = "127.0.0.1"` is the only protection. Do not change `bind` without also setting `requirePass`.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| Secrets management  | `./secrets.nix`              |
| Profile default     | `modules/profile/system.nix` |
