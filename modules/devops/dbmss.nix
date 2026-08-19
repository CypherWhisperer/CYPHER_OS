# modules/devops/dbmss.nix
# CypherOS DBMS layer.
#
# Design decisions baked into this file
#   - Postgres (primary), MariaDB (secondary/compat), Valkey (cache) are
#     "foundational" — installed, configured, dataDir'd onto their own
#     subvolumes, but NOT auto-started at boot. Start on demand with
#     `systemctl start postgresql` / `mysql` / `redis-<name>`.
#
#   - Meilisearch, MongoDB (mongodb-ce), Neo4j are "install only" — the
#     subvolume + tmpfiles provisioning exists now so enabling the service
#     later is a pure Nix-config change, no disk work. Their service blocks
#     below are commented out until actually needed.
#
#   - TimescaleDB is a Postgres extension, not a separate service — lives
#     inside the postgres block.
#
#   - Valkey is kept purely ephemeral (save = []); no persistence, so no
#     bind-mount is wired into its live path. If that ever changes, see the
#     commented block at the bottom of the redis section.
#
#   - Redis vs Valkey: same NixOS module, different `package` — see
#     services.redis.package below.
#
# ──────────────────────────────────────────────────────────────────────────────
# DBMSs BACKUPS
# ──────────────────────────────────────────────────────────────────────────────
# Design: DB-native dump tools (pg_dump, mariadb-dump) write timestamped,
# compressed, portable SQL files into /backup/dir/for/DBMSs/backups/<db>/.
# That directory is already inside the tree I periodically mirror to an
# external HDD manually:
# sudo nice -n -18 rsync -ahAXv --delete --info=progress2 /path/to/source/ /path/to/target/
# So no new backup destination or offsite mechanism is needed — the
# existing rsync habit picks these up automatically the next backup session.
#
# This is deliberately NOT trying to introduce restic/borg or a NAS — see
# docs/project/guide_backup_tooling.md for why that's a "later" upgrade, not a "now"
# requirement, given my actual current workflow.
#
# Btrfs snapshots (docs/project/guide_btrfs_snapshots.md) are a separate, faster,
# local-only safety net for "undo my last schema migration" — they are NOT
# a substitute for these dumps, and aren't part of the offsite path unless
# the backup external HDD is ever reformatted to Btrfs.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dbmsSubvolumes = [
    "postgres"
    "mariadb"
    "valkey"
    "meilisearch"
    "mongo"
    "neo4j"
  ];

  backupRoot = "/home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/DBMS_DATA_BACKUPS";
  retentionDays = 14;

  # Shared group so DB service users can write into a directory owned by
  # cypher-whisperer without needing root in the loop for every dump.
  backupGroup = "dbbackup";

  pgDumpScript = pkgs.writeShellScript "pg-backup" ''
    set -euo pipefail
    outdir="${backupRoot}/postgres"
    mkdir -p "$outdir"
    ts="$(date +%Y%m%d-%H%M%S)"
    ${pkgs.postgresql_18}/bin/pg_dumpall | ${pkgs.gzip}/bin/gzip > "$outdir/dump-$ts.sql.gz"
    find "$outdir" -name 'dump-*.sql.gz' -mtime +${toString retentionDays} -delete
  '';

  mariadbDumpScript = pkgs.writeShellScript "mariadb-backup" ''
    set -euo pipefail
    outdir="${backupRoot}/mariadb"
    mkdir -p "$outdir"
    ts="$(date +%Y%m%d-%H%M%S)"
    ${pkgs.mariadb}/bin/mariadb-dump --all-databases | ${pkgs.gzip}/bin/gzip > "$outdir/dump-$ts.sql.gz"
    find "$outdir" -name 'dump-*.sql.gz' -mtime +${toString retentionDays} -delete
  '';
in
{
  config = lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.dbmss.enable) {

    # setting up users and groups.
    users.groups.${backupGroup} = { };
    users.users.postgres.extraGroups = [ backupGroup ];
    users.users.mysql.extraGroups = [ backupGroup ];

    # ──────────────────────────────────────────────────────────────────────────
    # Mountpoints — top-level Btrfs siblings, never nested inside @home.
    # "x-systemd.mkdir" creates the mountpoint directory itself if missing;
    # NixOS's fstab generator does not do this automatically otherwise.
    # ──────────────────────────────────────────────────────────────────────────
    fileSystems = lib.genAttrs (map (name: "/dbms/${name}") dbmsSubvolumes) (
      path:
      let
        name = builtins.baseNameOf path;
      in
      {
        device = "/dev/sda1"; # match actual btrfs partition
        fsType = "btrfs";
        options = [
          "subvol=@dbms_${name}"
          "compress=zstd:3"
          "noatime"
          "x-systemd.mkdir"
        ];
      }
    );

    # ──────────────────────────────────────────────────────────────────────────
    # Ownership + permissions — the "configure-and-forget" replacement for
    # what StateDirectory= would have done automatically on the default path.
    # Parent traversal is a non-issue: /dbms/<name> IS the mountpoint itself.
    # ──────────────────────────────────────────────────────────────────────────
    systemd.tmpfiles.rules = [
      "d /dbms/postgres    0700 postgres     postgres     - -"
      "d /dbms/mariadb     0700 mysql        mysql        - -"
      "d /dbms/valkey      0700 redis        redis        - -"
      "d /dbms/meilisearch 0700 meilisearch  meilisearch  - -"
      "d /dbms/mongo       0700 mongodb      mongodb      - -"
      "d /dbms/neo4j       0700 neo4j        neo4j        - -"
      # Backup directories setup.
      "d ${backupRoot}             2775 cypher-whisperer ${backupGroup} - -"
      "d ${backupRoot}/postgres    2775 postgres         ${backupGroup} - -"
      "d ${backupRoot}/mariadb     2775 mysql            ${backupGroup} - -"
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # PostgreSQL — primary. TimescaleDB loaded as an extension, not a
    # separate service.
    # ──────────────────────────────────────────────────────────────────────────
    services.postgresql = {
      enable = true;
      # pin explicitly rather than relying on stateVersion drift
      # run pg_upgrade on version bump.
      package = pkgs.postgresql_18;
      dataDir = "/dbms/postgres";
      enableTCPIP = false; # socket-only; flip if remote/container access needed.

      # authentication: pg_hba.conf rules. Controls who can connect, from where,
      # and with what auth method:
      #   local  = Unix socket connections
      #   host   = TCP/IP connections
      #   md5    = password (hashed). scram-sha-256 is stronger but less compatible.
      #   trust  = no password (dev only — never in production)
      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE  USER      ADDRESS         METHOD
        local   all       postgres                  trust
        local   all       all                       md5
        host    all       all       127.0.0.1/32    md5
        host    all       all       ::1/128         md5
      '';

      extensions =
        ps: with ps; [
          postgis
          timescaledb

          # ────────────────────────────────────────────────────────────────────────
          # error: Refusing to evaluate package 'timescaledb_toolkit-1.21.0' in
          #  /nix/store/3a2vdn5i7vd2wl654xs8nb52jf1v6cbh-source/pkgs/servers/sql/postgresql/ext/timescaledb_toolkit.nix:40 because it has problems:
          #   - broken: This package is broken.
          #   See also https://nixos.org/manual/nixpkgs/unstable#sec-problems
          #   To allow evaluation regardless, use:
          #   - Nixpkgs import: import nixpkgs { config = <below code>; }
          #   - NixOS: nixpkgs.config = <below code>;
          #   - nix-* commands: Put below code in ~/.config/nixpkgs/config.nix
          #
          #   {
          #     problems.handlers = {
          #       timescaledb_toolkit.broken = "warn"; # or "ignore"
          #     };
          #   }
          # ────────────────────────────────────────────────────────────────────────
          #timescaledb_toolkit

          # ────────────────────────────────────────────────────────────────────────
          # pgvector: PostgreSQL extension for vector similarity search. Required for
          # AI/ML workloads (embeddings, RAG pipelines) that store vectors alongside
          # relational data. Installed as a package — must be enabled per-database:
          #   CREATE EXTENSION vector;
          # See: https://github.com/pgvector/pgvector
          # ────────────────────────────────────────────────────────────────────────
          pgvector

          # Extras: Observer performance, and need and decisively evaluate.

          # ────────────────────────────────────────────────────────────────────────
          # same Error as timescaledb_toolkit above; see that block for how to override.
          # ────────────────────────────────────────────────────────────────────────
          # citus
          # lantern
          # pg_auto_failover
          # pg_ed25519
          # pgaudit
          # sqlite_fdw

          age
          anonymizer
          apache_datasketches
          ip4r
          pg_background
          pg_bigm
          pg_cron
          pg_csv
          pg_duckdb
          pg_graphql
          pg_partman
          pg_repack
          pg_roaringbitmap
          pg_safeupdate
          pg_search
          pg_squeeze
          pg_textsearch
          pg_topn
          pg_uuidv7
          pgrouting
          pgsodium
          pgsql-http
          pgvectorscale
          plpgsql_check
          plpython3
          pointcloud
          repmgr
          rum
          system_stats
          tsja
          vectorchord
          wal2json
        ];

      # settings: postgresql.conf parameters.
      settings = {
        shared_preload_libraries = "timescaledb";

        # log_connections / log_disconnections: useful during development to see
        # all connection activity in `journalctl -u postgresql`.
        log_connections = true;
        log_disconnections = true;

        # Tuning for a dev machine (not production values):
        # shared_buffers: ~25% of RAM is the production recommendation.
        # On a dev machine, 256MB is fine.
        shared_buffers = "256MB";
      };

      # Fill in as real projects arrive.
      ensureDatabases = [ "cypher_test" ];
      ensureUsers = [
        {
          name = "cypher_test";
          # ensureDBOwnership: makes cypher_dev owner of the cypher_dev database.
          ensureDBOwnership = true;
        }
      ];
    };

    # Require the mount to be up before Postgres can start — belt-and-suspenders
    # even though /dbms/postgres is a top-level sibling with no nesting-ordering
    # risk; still guards against the mount being slow/delayed for any reason.
    systemd.services.postgresql = {
      serviceConfig.RequiresMountsFor = [ "/dbms/postgres" ];
      # On-demand: unit is fully configured (initdb/ensureDatabases/ensureUsers
      # all wired up) but does NOT start automatically at boot.
      wantedBy = lib.mkForce [ ];
    };
    # ──────────────────────────────────────────────────────────────────────────
    # PostgreSQL data Backup.
    # ──────────────────────────────────────────────────────────────────────────
    # pg_dumpall/mariadb-dump need a *running* server to connect to, not just
    # the data files — but the services are on-demand (modules/devops/databases.nix
    # disables their WantedBy).
    #
    # `Wants` + `After` here means the daily timer briefly wakes the DB specifically
    # to take the dump, then it's your call whether to `systemctl stop` it again
    # afterwards (it won't stop itself automatically — adding ExecStopPost on the
    # backup service could feature/support that).
    #
    # This is the one deliberate exception to "purely on-demand":
    #   - unattended dumps need something running to dump from.
    systemd.services.pg-backup = {
      description = "Dump all PostgreSQL databases to ${backupRoot}/postgres";
      wants = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        ExecStart = "${pgDumpScript}";
      };
    };
    systemd.timers.pg-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true; # catches up on next boot if machine was off at scheduled time
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # MariaDB — secondary/compat.
    # ──────────────────────────────────────────────────────────────────────────
    services.mysql = {
      enable = true;
      # ────────────────────────────────────────────────────────────────────────
      # services.mysql is shared infrastructure for BOTH real MySQL and
      # MariaDB — which one you actually run is purely this attribute.
      # ────────────────────────────────────────────────────────────────────────
      package = pkgs.mariadb_114; # Version-pinned explicitly.
      dataDir = "/dbms/mariadb";

      # ── Bootstrap: databases and users created on first start ──────
      # These only ever apply ONCE, the very first time the service
      # starts against an empty data directory — they will never
      # retroactively delete or modify something you created since.
      # ────────────────────────────────────────────────────────────────────────
      ensureDatabases = [ ];
      # ────────────────────────────────────────────────────────────────────────
      # This module can only create unix_socket-authenticated accounts,
      # which conflicts with a password/TCP-based app user. such dbs
      # are/should be created and owned entirely by app db schema instead.
      # ────────────────────────────────────────────────────────────────────────
      ensureUsers = [ ];

      # NOTE (ties directly into the auth_socket discussion above): ensureUsers,
      # by NixOS's own design, authenticates via Unix socket matching an OS user
      # of the SAME NAME — no password at all.
      #
      # That means an app connecting over TCP with a password will NOT
      # authenticate against a user created this way. ensureUsers is best suited
      # to services that run AS that Linux user and connect via socket — not a
      # dev server's mysqli/TCP connection. For a password-based app user, you'll
      # want to create it manually (see initialScript below) rather than
      # rely on ensureUsers for this specific PoC.
      # ────────────────────────────────────────────────────────────────────────
      #   ensurePermissions = {
      #     "poc_auth.*" = "ALL PRIVILEGES";
      #   };
      # }
      # ];

      # ── Password-based app user + root hardening notes ─────────────
      # A file of raw SQL run ONCE on first startup — the right place to create
      # a genuinely password-authenticated app user, since ensureUsers (above)
      # can't do that. Point this at a real file rather than inlining credentials
      # directly in this .nix file, so the password doesn't end up readable in
      # Nix store history / `nix store diff-closures` output indefinitely.
      #
      # initialScript = pkgs.writeText "mysql-init.sql" ''
      #   CREATE USER IF NOT EXISTS 'auth_poc_app'@'localhost'
      #     IDENTIFIED WITH mysql_native_password BY 'REPLACE_ME_WITH_A_REAL_SECRET';
      #   GRANT ALL PRIVILEGES ON auth_poc.* TO 'auth_poc_app'@'localhost';
      #   FLUSH PRIVILEGES;
      # '';

      # ── Networking / bind address ───────────────────────────────────────────
      # `settings` maps directly onto my.cnf-style [mysqld] options.
      # Left commented since a PoC or app talking to `localhost` via socket or
      # 127.0.0.1 loopback doesn't need the server listening on any
      # external interface at all — only uncomment if something OTHER
      # than this same machine needs to reach it.
      # ────────────────────────────────────────────────────────────────────────
      # settings.mysqld.bind-address = "0.0.0.0";
      # settings.mysqld.port = 3306;

      # ── Replication (not relevant to a single-instance PoC/app) ─────────────
      # Meaningful once you have more than one MySQL/MariaDB
      # instance and want one to mirror another.
      # ────────────────────────────────────────────────────────────────────────
      # replication = {
      #   role = "master"; # or "slave"
      #   serverId = 1;
      # };

      # ── Galera clustering (multi-primary, several servers) ──────────────────
      # This is how MariaDB does synchronous multi-node clustering. exists if
      # "database" ever means "several coordinated servers" rather than one box.
      # ────────────────────────────────────────────────────────────────────────
      # galeraCluster = {
      #   enable = true;
      #   package = pkgs.mariadb-galera;
      #   clusterName = "my-cluster";
      # };
    };

    systemd.services.mysql = {
      serviceConfig.RequiresMountsFor = [ "/dbms/mariadb" ];
      # ── Auto-start override (point 4.1) ───────────────────────────────────────
      # This meand the service DECLARED (binary present, config generated,
      # ensureDatabases/ensureUsers logic available) but NOT started automatically
      # at boot — i.e. you'd bring it up manually with `sudo systemctl start mysql`
      # ──────────────────────────────────────────────────────────────────────────
      wantedBy = lib.mkForce [ ];
    };
    # ── Firewall (only relevant if bind-address is opened above) ──────
    # networking.firewall.allowedTCPPorts = [ 3306 ];

    # ──────────────────────────────────────────────────────────────────────────
    # MariaDB data Backup.
    # ──────────────────────────────────────────────────────────────────────────
    systemd.services.mariadb-backup = {
      description = "Dump all MariaDB databases to ${backupRoot}/mariadb";
      wants = [ "mysql.service" ];
      after = [ "mysql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "mysql";
        ExecStart = "${mariadbDumpScript}";
      };
    };
    systemd.timers.mariadb-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Valkey (via the redis module) — cache, kept ephemeral.
    # ──────────────────────────────────────────────────────────────────────────
    services.redis.package = pkgs.valkey; # the entire Redis->Valkey migration.
    services.redis.servers."" = {
      enable = true;
      save = [ ]; # disable RDB; nothing here worth persisting (ephemeral-cache use)
      appendOnly = false;
    };

    systemd.services."redis-" = {
      # ── Auto-start override (point 4.1) ─────────────────────────────────────
      # This meand the service DECLARED (binary present, config generated,
      # ensureDatabases/ensureUsers logic available) but NOT started automatically
      # at boot — i.e. you'd bring it up manually with `sudo systemctl start redis-<name>`
      # ────────────────────────────────────────────────────────────────────────
      wantedBy = lib.mkForce [ ];
    };

    # If a future project needs Valkey to actually persist (source-of-truth
    # role, not pure cache), flip the block above to appendOnly = true /
    # a real `save` schedule, then wire the subvolume in like this:
    # ──────────────────────────────────────────────────────────────────────────
    # fileSystems."/var/lib/redis" = {
    #   device = "/dbms/valkey";
    #   options = [ "bind" ];
    # };
    # systemd.services."redis-".serviceConfig.RequiresMountsFor = [ "/var/lib/redis" ];
    # ──────────────────────────────────────────────────────────────────────────
    # (Bind-mounting onto the module's hardcoded path is simpler than fighting
    # its systemd sandbox with a custom `settings.dir` + ReadWritePaths override.)

    # ──────────────────────────────────────────────────────────────────────────
    # Install-only tier — packages available now, services enabled later.
    # ──────────────────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      meilisearch
      neo4j

      # ── PostgreSQL tooling ──────────────────────────────────────────────────
      pgcli # psql replacement with autocomplete and syntax highlighting
      timescaledb-tune
      postgrest
      postgres-language-server

      # ── MongoDB CLI tools ───────────────────────────────────────────────────
      mongodb-tools # mongo{dump,restore,export,import,stat}
      mongodb-atlas-cli # manage Atlas cloud clusters from the terminal
      mongodb-ce
      mongodb-cli

      # ── Redis tooling ───────────────────────────────────────────────────────
      # Redis rules out in favor of valkey.
      #redis # installs redis-cli (the server is the service above)
      redis-dump
      redisinsight

      # ── MySQL/MariaDB tooling ───────────────────────────────────────────────
      # ── Optional: CLI ergonomics ────────────────────────────────────────────
      mariadb_114 # provides the `mysql/mariadb` CLI client itself
      mysql-shell
      mysqltuner
      mysql2pgsql # MySQL dump to Postgres-loadable files.
      # mycli gives autocompletion + syntax highlighting in the mysql
      # shell — a nice-to-have, not required for anything above to work tho.
      # ──────────────────────────────────────────────────────────────────────────
      # mycli

      # ── SQLite ──────────────────────────────────────────────────────────────
      sqlite # file-based DB; no daemon
      sqlitebrowser # Kept over sqlitestudio, more widely used
      sqlite3-to-mysql # Python tool to transfer SQLite data to MySQL.
      litecli # sqlite CLI with autocomplete and syntax highlighting
      sqlite-vec
      sqlite-utils
      sqlite-rsync
      sqlite-analyzer
      #sqlite-jdbc # Access and create DBs in Java.
      #sqlite-interactive

      # ── Universal SQL client ──────────────────────────────────────────────────
      usql # single CLI for PostgreSQL, MySQL, SQLite, and more

      # ── GUI clients ───────────────────────────────────────────────────────────
      dbgate # universal DB GUI; PostgreSQL, MySQL, SQLite, MongoDB, Redis
      mongodb-compass # official MongoDB GUI; for deep MongoDB work (explain plans, aggregations)

      # ── EXCLUDED ──────────────────────────────────────────────────────────────

      # ── ClickHouse ────────────────────────────────────────────────────────────
      # Column-oriented OLAP database. Extremely fast for analytical queries over
      # large datasets. Increasingly common in observability stacks (as a Loki
      # backend), data engineering pipelines, and anywhere you'd outgrow PostgreSQL
      # for read-heavy analytics. CLI only here — run the server via Docker:
      #   docker run -d -p 8123:8123 -p 9000:9000 clickhouse/clickhouse-server
      # ────────────────────────────────────────────────────────────────────────
      # EXCLLUDED: Not currently needed. Refer to documentation.
      #clickhouse # clickhouse-client CLI

      # mongodb (server)  # SSPL license makes nixpkgs inclusion unreliable;
      #  use Docker instead: `docker run -d -p 27017:27017 mongo:latest`
      # uncomment if/when services.mongodb becomes stable in nixpkgs
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # Meilisearch, MongoDB, Neo4j service blocks
    # ──────────────────────────────────────────────────────────────────────────
    # Uncomment and fill in when a project actually needs one running.
    # The subvolume + tmpfiles ownership above is already correct for each.
    # ──────────────────────────────────────────────────────────────────────────
    # services.meilisearch = {
    #   enable = true;
    #   listenAddress = "127.0.0.1";
    #   # dataDir is a real, named option on this module:
    #   # dataDir = "/dbms/meilisearch";
    # };
    #
    # services.mongodb = {
    #   enable = true;
    #   dataDir = "/dbms/mongo";
    #   bind_ip = "127.0.0.1";
    # };
    #
    # services.neo4j = {
    #   enable = true;
    #   directories.home = "/dbms/neo4j";
    # };

    # ──────────────────────────────────────────────────────────────────────────
    # Redis: Ruled out in Favor of valkey, Kept for compat but commented out.
    # ──────────────────────────────────────────────────────────────────────────
    # services.redis.servers.dev = {
    #   enable = true;
    #   bind = "127.0.0.1";
    #   port = 6379;
    #
    #   # requirePass: UNSET here for local dev convenience. For staging/prod,
    #   # use sops-nix to inject the password as a secret:
    #   #   requirePassFile = config.sops.secrets.redis_password.path;
    #   # ──────────────────────────────────────────────────────────────────────
    #   # requirePass = "devpassword";  # uncomment for local auth testing
    #
    #   save = [
    #     [
    #       900
    #       1
    #     ]
    #     [
    #       300
    #       10
    #     ]
    #     [
    #       60
    #       10000
    #     ]
    #   ];
    #
    #   # loglevel: "debug" | "verbose" | "notice" | "warning"
    #   # "notice" is appropriate for dev — less noise than "verbose".
    #   settings.loglevel = "notice";
    # };
  };
}
