# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.devops = {
    enable = lib.mkEnableOption "DevOps infrastructure";

    cicd.enable = lib.mkEnableOption "CI/CD tooling (act, gh, actionlint, github-runner)";
    dbmss.enable = lib.mkEnableOption "local development database services (PostgreSQL, Redis, SQLite, MongoDB tools)";
    containers.enable = lib.mkEnableOption "container tooling (Docker, Podman, image inspection, scanning)";
    kubernetes.enable = lib.mkEnableOption "Kubernetes tooling (k3s, kubectl, Helm, k3d, kind, cluster utilities)";

    iac = {
      enable = lib.mkEnableOption "Infrastructure as Code tooling (OpenTofu, Ansible, Pulumi, Terragrunt)";

      terraform.enable = lib.mkEnableOption "Terraform (HashiCorp BSL — prefer OpenTofu for new projects)";
    };

    secrets = {
      enable = lib.mkEnableOption "secrets management tooling (sops-nix, age, Vault)";

      vault.enable = lib.mkEnableOption "Vault (OCI-containerised)";
    };

    cloud = {
      enable = lib.mkEnableOption "cloud provider CLIs and supporting tooling";

      aws.enable = lib.mkEnableOption "AWS CLI v2 and AWS-ecosystem tools";
      gcp.enable = lib.mkEnableOption "Google Cloud SDK (gcloud, gsutil, bq)";
      azure.enable = lib.mkEnableOption "Azure CLI";
    };

    observability = {
      enable = lib.mkEnableOption "local observability stack (Prometheus, Grafana, Loki)";

      loki.enable = lib.mkEnableOption "Loki log aggregation and Promtail log shipper";
      grafana.enable = lib.mkEnableOption "Grafana dashboards";
      prometheus.enable = lib.mkEnableOption "Prometheus metrics collection and node exporter";
    };

    networking = {
      enable = lib.mkEnableOption "reverse proxy and local networking tooling";

      caddy.enable = lib.mkEnableOption "Caddy web server / reverse proxy";
      traefik.enable = lib.mkEnableOption "Traefik container-aware reverse proxy";
    };
  };
}
