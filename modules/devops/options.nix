# modules/devops/options.nix

{ lib, ... }:

{
  options.cypher-os.devops = {
    enable = lib.mkEnableOption "DevOps infrastructure";

    containers.enable = lib.mkEnableOption "container tooling (Docker, Podman, image inspection, scanning)";
    kubernetes.enable = lib.mkEnableOption "Kubernetes tooling (k3s, kubectl, Helm, k3d, kind, cluster utilities)";
    dbmss.enable = lib.mkEnableOption "local development database services (PostgreSQL, Redis, SQLite, MongoDB tools)";

    iac.enable = lib.mkEnableOption "Infrastructure as Code tooling (OpenTofu, Ansible, Pulumi, Terragrunt)";
    iac.terraform.enable = lib.mkEnableOption "Terraform (HashiCorp BSL — prefer OpenTofu for new projects)";

    secrets.enable = lib.mkEnableOption "secrets management tooling (sops-nix, age, Vault)";
    secrets.vault.enable = lib.mkEnableOption "Vault (OCI-containerised)";

    n8n.enable = lib.mkEnableOption "n8n workflow automation (OCI-containerised)";

    cloud.enable = lib.mkEnableOption "cloud provider CLIs and supporting tooling";
    cloud.aws.enable = lib.mkEnableOption "AWS CLI v2 and AWS-ecosystem tools";
    cloud.azure.enable = lib.mkEnableOption "Azure CLI";
    cloud.gcp.enable = lib.mkEnableOption "Google Cloud SDK (gcloud, gsutil, bq)";

    observability.enable = lib.mkEnableOption "local observability stack (Prometheus, Grafana, Loki)";
    observability.prometheus.enable = lib.mkEnableOption "Prometheus metrics collection and node exporter";
    observability.grafana.enable = lib.mkEnableOption "Grafana dashboards";
    observability.loki.enable = lib.mkEnableOption "Loki log aggregation and Promtail log shipper";

    networking.enable = lib.mkEnableOption "reverse proxy and local networking tooling";
    networking.caddy.enable = lib.mkEnableOption "Caddy web server / reverse proxy";
    networking.traefik.enable = lib.mkEnableOption "Traefik container-aware reverse proxy";

    cicd.enable = lib.mkEnableOption "CI/CD tooling (act, gh, actionlint, github-runner)";
  };
}
