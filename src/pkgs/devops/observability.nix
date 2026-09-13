# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/observability.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.devops;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.observability.enable) {

    # ── Prometheus ─────────────────────────────────────────────────────────────
    # Time-series metrics collection and storage. Scrapes metrics from configured
    # targets on a pull model — targets expose a /metrics HTTP endpoint; Prometheus
    # fetches it on a configurable interval and stores the data locally.
    #
    # Web UI available at http://localhost:9090 after activation.
    # PromQL (Prometheus Query Language) is the query interface; Grafana visualises
    # the same data with richer dashboards.
    services.prometheus = lib.mkIf cfg.observability.prometheus.enable {
      enable = true;
      port = 9090;

      # globalConfig: settings applied to all scrape jobs unless overridden.
      globalConfig = {
        scrape_interval = "15s"; # how often to scrape targets
        evaluation_interval = "15s"; # how often to evaluate alert rules
      };

      # exporters.node: the node exporter exposes host-level metrics — CPU, memory,
      # disk I/O, network, filesystem. The most fundamental Prometheus exporter.
      # Metrics endpoint: http://localhost:9100/metrics
      exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
          "time"
          "uname"
        ];
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            }
          ];
        }
        # Add more scrape targets here as you deploy services:
        # { job_name = "caddy"; static_configs = [{ targets = ["localhost:2019"]; }]; }
        # { job_name = "k3s";   static_configs = [{ targets = ["localhost:10250"]; }]; }
      ];
    };

    # ── Grafana ────────────────────────────────────────────────────────────────
    # Dashboard and visualisation layer for metrics and logs. Connects to Prometheus
    # (metrics) and Loki (logs) as data sources. The standard local observability UI.
    #
    # Web UI: http://localhost:3001 (3001 to avoid collision with common dev servers)
    # Default credentials on first boot: admin / admin (change immediately)

    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: ASSERTION ERROR:
    #
    # Grafana's secret key (services.grafana.settings.security.secret_key)
    # doesn't have a default value anymore. Please generate your own and use a
    # file-provider on this option! See also
    # https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#secret_key
    # for more information.
    #
    #See https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-database-encryption/#re-encrypt-secrets
    # on how to re-encrypt.
    #
    # As stated in the NixOS changelog for 26.05, there's no official way to
    # rotate. Either hard-code the old key ("SW2YcwTIb9zpOOhoPsMm") if your
    # setup doesn't have any secrets in the DB that need special protection or
    # perform a rotation with a 3rd-party tool:
    # (https://github.com/erooke/grafana-secretkey-rotation-tool/tree/d9dc788902fa5185e15cb15ce6129f7237ab6138).
    # ──────────────────────────────────────────────────────────────────────────
    services.grafana = lib.mkIf cfg.observability.grafana.enable {
      enable = true;

      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3001;
          domain = "localhost";
        };

        # analytics.reporting_enabled: disable telemetry sent to grafana.com.
        analytics.reporting_enabled = false;
      };

      # provision.datasources: automatically wire Prometheus and Loki as data
      # sources on first start. Without this, you'd configure them manually
      # through the Grafana UI on every rebuild.
      provision.datasources.settings.datasources =
        lib.optionals cfg.observability.prometheus.enable [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.port}";
            isDefault = true;
          }
        ]
        ++ lib.optionals cfg.observability.loki.enable [
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:3100";
          }
        ];
    };

    # ── Loki ───────────────────────────────────────────────────────────────────
    # Log aggregation system from Grafana Labs. Indexes log metadata (labels) not
    # log content, making it cheap to store and query large log volumes.
    # Queryable from Grafana using LogQL (similar syntax to PromQL).
    #
    # Loki itself stores and queries logs. Promtail (below) ships logs into Loki.
    services.loki = lib.mkIf cfg.observability.loki.enable {
      enable = true;
      configFile = pkgs.writeText "loki-config.yaml" (
        builtins.toJSON {
          auth_enabled = false;

          server.http_listen_port = 3100;

          ingester = {
            lifecycler = {
              address = "127.0.0.1";
              ring = {
                kvstore.store = "inmemory";
                replication_factor = 1;
              };
              final_sleep = "0s";
            };
            chunk_idle_period = "5m";
            chunk_retain_period = "30s";
          };

          schema_config.configs = [
            {
              from = "2024-01-01";
              store = "boltdb-shipper";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];

          storage_config = {
            boltdb_shipper = {
              active_index_directory = "/var/lib/loki/index";
              cache_location = "/var/lib/loki/cache";
            };
            filesystem.directory = "/var/lib/loki/chunks";
          };

          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
          };
        }
      );
    };

    # ── Promtail ───────────────────────────────────────────────────────────────
    # The log shipper that feeds Loki. Tails log files and the systemd journal,
    # attaches labels (hostname, unit name, etc.), and forwards to Loki.
    # Think of Promtail as the Prometheus node exporter, but for logs.
    #
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: PROMTAIL REACHED END OF LIFE
    # ──────────────────────────────────────────────────────────────────────────
    # Assertion error:
    #
    # - The option definition `services.promtail' in
    # `/nix/store/[hash]/src/pkgs/devops/observability.nix'
    # no longer has any effect; please remove it.
    #  The promtail module has been removed, as promtail reached its end of life
    # Consider migrating to `grafana-alloy` (`services.alloy.enable`), or, if
    # you are looking for something light-weight, `fluent-bit`
    # (`services.fluent-bit.enable`). See:
    # <https://grafana.com/docs/alloy/latest/set-up/migrate/> or
    # <https://docs.fluentbit.io/manual/data-pipeline/outputs/loki>.
    # ──────────────────────────────────────────────────────────────────────────

    #services.promtail = lib.mkIf cfg.observability.loki.enable {
    #  enable = true;
    #
    #  configuration = {
    #    server = {
    #      http_listen_port = 9080;
    #      grpc_listen_port = 0;
    #    };
    #
    #    positions.filename = "/var/lib/promtail/positions.yaml";
    #
    #    clients = [
    #      {
    #        url = "http://localhost:3100/loki/api/v1/push";
    #      }
    #    ];
    #
    #    scrape_configs = [
    #      {
    #        job_name = "journal";
    #        journal = {
    #          max_age = "12h";
    #          labels = {
    #            job = "systemd-journal";
    #            host = config.networking.hostName;
    #          };
    #        };
    #        relabel_configs = [
    #          {
    #            source_labels = [ "__journal__systemd_unit" ];
    #            target_label = "unit";
    #          }
    #        ];
    #      }
    #    ];
    #  };
    #};

    # ── Supporting packages ────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [

      # promtail: also a CLI tool for testing pipeline configs and pushing log
      # entries manually. Installed as a package even though the service is
      # declared above — the service and the CLI come from the same derivation.
      # (NixOS declares the service; this ensures `promtail` is on PATH.)
      promtail

      # ── DEFERRED — extended observability ────────────────────────────────────
      # prometheus-alertmanager  # route and de-duplicate Prometheus alerts
      #                          # blocked on: having something to alert on
      # vector                   # high-performance log/metric pipeline (Rust)
      #                          # deferred: promtail covers initial needs
      # opentelemetry-collector  # OTEL collector for traces + metrics + logs
      #                          # deferred: traces are Phase 4/5 territory
      # jaeger                   # distributed tracing backend
      #                          # deferred: requires instrumented services first
    ];

  };
}
