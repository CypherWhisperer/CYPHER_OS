# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.devops;
in
{
  imports = [
    ./options.nix
    ./cicd.nix
    ./cloud.nix
    ./containers.nix
    ./dbmss.nix
    ./iac.nix
    ./kubernetes.nix
    ./networking.nix
    ./observability.nix
    ./secrets.nix
  ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.devops.enable = lib.mkDefault true;

    cypher-os.pkgs.devops.cicd.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.devops.dbmss.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.devops.containers.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.devops.kubernetes.enable = lib.mkDefault cfg.enable;

    #cypher-os.pkgs.devops.iac.enable = lib.mkDefault cfg.enable; # overriden
    cypher-os.pkgs.devops.iac.enable = lib.mkDefault false;

    cypher-os.pkgs.devops.iac.terraform.enable = lib.mkDefault cfg.iac.enable;

    #cypher-os.pkgs.devops.secrets.enable = lib.mkDefault cfg.enable; # overriden
    cypher-os.pkgs.devops.secrets.enable = lib.mkDefault false;

    cypher-os.pkgs.devops.secrets.vault.enable = lib.mkDefault cfg.secrets.enable;

    #cypher-os.pkgs.devops.cloud.enable = lib.mkDefault cfg.enable; # overriden
    cypher-os.pkgs.devops.cloud.enable = lib.mkDefault false;

    cypher-os.pkgs.devops.cloud.aws.enable = lib.mkDefault cfg.cloud.enable;
    cypher-os.pkgs.devops.cloud.gcp.enable = lib.mkDefault cfg.cloud.enable;
    cypher-os.pkgs.devops.cloud.azure.enable = lib.mkDefault cfg.cloud.enable;

    #cypher-os.pkgs.devops.observability.enable = lib.mkDefault cfg.enable; # overriden
    cypher-os.pkgs.devops.observability.enable = lib.mkDefault false;

    cypher-os.pkgs.devops.observability.loki.enable = lib.mkDefault cfg.observability.enable;
    cypher-os.pkgs.devops.observability.grafana.enable = lib.mkDefault cfg.observability.enable;
    cypher-os.pkgs.devops.observability.prometheus.enable = lib.mkDefault cfg.observability.enable;

    cypher-os.pkgs.devops.networking.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.devops.networking.caddy.enable = lib.mkDefault cfg.networking.enable;
    cypher-os.pkgs.devops.networking.traefik.enable = lib.mkDefault cfg.networking.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.cicd.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.cicd.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.dbmss.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.dbmss.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.containers.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.containers.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.kubernetes.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.kubernetes.enable requires cypher-os.pkgs.devops.enable.
        '';
      }

      {
        assertion = cfg.iac.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.iac.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.iac.terraform.enable -> cfg.iac.enable;
        message = ''
          cypher-os.pkgs.devops.iac.terraform.enable requires cypher-os.pkgs.devops.iac.enable.
        '';
      }

      {
        assertion = cfg.secrets.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.secrets.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.secrets.vault.enable -> cfg.secrets.enable;
        message = ''
          cypher-os.pkgs.devops.secrets.vault.enable requires cypher-os.pkgs.devops.secrets.enable.
        '';
      }

      {
        assertion = cfg.cloud.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.cloud.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.cloud.aws.enable -> cfg.cloud.enable;
        message = ''
          cypher-os.pkgs.devops.cloud.aws.enable requires cypher-os.pkgs.devops.cloud.enable.
        '';
      }
      {
        assertion = cfg.cloud.gcp.enable -> cfg.cloud.enable;
        message = ''
          cypher-os.pkgs.devops.cloud.gcp.enable requires cypher-os.pkgs.devops.cloud.enable.
        '';
      }
      {
        assertion = cfg.cloud.azure.enable -> cfg.cloud.enable;
        message = ''
          cypher-os.pkgs.devops.cloud.azure.enable requires cypher-os.pkgs.devops.cloud.enable.
        '';
      }

      {
        assertion = cfg.observability.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.observability.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.observability.loki.enable -> cfg.observability.enable;
        message = ''
          cypher-os.pkgs.devops.observability.loki.enable requires cypher-os.pkgs.devops.observability.enable.
        '';
      }
      {
        assertion = cfg.observability.grafana.enable -> cfg.observability.enable;
        message = ''
          cypher-os.pkgs.devops.observability.grafana.enable requires cypher-os.pkgs.devops.observability.enable.
        '';
      }
      {
        assertion = cfg.observability.prometheus.enable -> cfg.observability.enable;
        message = ''
          cypher-os.pkgs.devops.observability.prometheus.enable requires cypher-os.pkgs.devops.observability.enable.
        '';
      }

      {
        assertion = cfg.networking.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.devops.networking.enable requires cypher-os.pkgs.devops.enable.
        '';
      }
      {
        assertion = cfg.networking.caddy.enable -> cfg.networking.enable;
        message = ''
          cypher-os.pkgs.devops.networking.caddy.enable requires cypher-os.pkgs.devops.networking.enable.
        '';
      }
      {
        assertion = cfg.networking.traefik.enable -> cfg.networking.enable;
        message = ''
          cypher-os.pkgs.devops.networking.traefik.enable requires cypher-os.pkgs.devops.networking.enable.
        '';
      }
    ];
  };
}
