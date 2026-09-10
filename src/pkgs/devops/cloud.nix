# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/cloud.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.devops;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.cloud.enable) {

    environment.systemPackages =
      lib.optionals cfg.cloud.aws.enable (
        with pkgs;
        [

          # ── AWS CLI v2 ────────────────────────────────────────────────────────
          # The primary AWS command-line interface. Manages every AWS service through
          # a unified `aws <service> <subcommand>` API. Configure with:
          #   aws configure   (stores credentials in ~/.aws/credentials)
          # All CloudWatch Logs streaming is built in:
          #   aws logs tail /aws/lambda/my-function --follow
          # (replaces the unmaintained awslogs third-party tool)
          awscli2

          # ── EKS cluster management ────────────────────────────────────────────
          # eksctl: the official CLI for Amazon EKS. Creates and manages EKS clusters
          # via CloudFormation, with sensible defaults that would otherwise require
          # manual steps across EC2, IAM, VPC, and EKS. Use after learning base
          # Kubernetes concepts (kubectl, Helm) on k3s/k3d first.
          # CLI: eksctl create cluster --name dev --region us-east-1
          eksctl

          # ── AWS credential helper ─────────────────────────────────────────────
          # aws-vault: stores and rotates AWS credentials in the OS keychain
          # (or a GPG-encrypted store). Injects temporary STS credentials into
          # subprocesses — never writes long-lived keys to ~/.aws/credentials.
          # CLI: aws-vault exec my-profile -- aws s3 ls
          aws-vault

          # ── SAM CLI ───────────────────────────────────────────────────────────
          # AWS Serverless Application Model CLI. Build, test, and deploy Lambda
          # functions and serverless applications locally before pushing to AWS.
          # Requires Docker for local Lambda invocation.
          # CLI: sam build && sam local invoke
          # DEFERRED: uncomment when reaching Lambda/serverless work
          # aws-sam-cli
        ]
      )

      ++ lib.optionals cfg.cloud.azure.enable (
        with pkgs;
        [

          # ── Azure CLI ─────────────────────────────────────────────────────────
          # Microsoft's official CLI for managing Azure resources. The Azure
          # equivalent of awscli2. Sign in with: az login
          # Core learning surfaces: az vm, az network, az storage, az aks
          azure-cli
        ]
      )

      ++ lib.optionals cfg.cloud.gcp.enable (
        with pkgs;
        [

          # ── Google Cloud SDK ──────────────────────────────────────────────────
          # Bundles gcloud (the primary CLI), gsutil (Cloud Storage), and bq
          # (BigQuery). Note: because this installation is managed by Nix, you
          # cannot install additional SDK components via `gcloud components install`.
          # Components not in the default bundle must be installed separately as Nix
          # packages (e.g. pkgs.google-cloud-sdk-gce for GCE-specific tooling).
          # Authenticate: gcloud auth login && gcloud config set project <PROJECT_ID>
          google-cloud-sdk
        ]
      )

      ++ (with pkgs; [

        # ── Cloud-agnostic tooling ────────────────────────────────────────────

        # steampipe: SQL query interface over cloud provider APIs. Run SQL against
        # AWS, Azure, GCP resources without writing code. Excellent for learning
        # cloud resource relationships and for quick audits.
        # CLI: steampipe query "select instance_id, state from aws_ec2_instance"
        # DEFERRED: uncomment when working across multiple cloud providers
        # steampipe

        # infracost: cost estimation for Terraform/OpenTofu plans. Shows how a
        # `tofu plan` will change your cloud bill before you apply.
        # CLI: infracost breakdown --path .
        # DEFERRED: relevant once writing real IaC that provisions cloud resources
        # infracost
      ]);

  };
}
