# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/iac.nix
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
  imports = [
    ./options.nix
    ./terraform.nix
  ];

  config = lib.mkIf (cfg.enable && cfg.iac.enable) {
    environment.systemPackages = with pkgs; [

      # ── OpenTofu ──────────────────────────────────────────────────────────────
      # FOSS fork of Terraform (MPL-2.0); functionally identical for all practical
      # use. Prefer for new personal projects — cannot be relicensed. CLI: `tofu`.
      opentofu

      # ── Version management ────────────────────────────────────────────────────
      # tenv: version manager for opentofu/terraform/terragrunt. Pin per-project
      # via .opentofu-version or .terraform-version files.
      tenv

      # ── Linting and documentation ─────────────────────────────────────────────
      tflint # linter for HCL; catches errors before `tofu apply`
      terraform-docs # generates README tables of variables, outputs, resources

      # ── Terragrunt ────────────────────────────────────────────────────────────
      # DRY wrapper around Terraform/OpenTofu; adds remote state management and
      # module composition. Learn plain Terraform/OpenTofu first; add this when
      # your configs repeat.
      terragrunt

      # ── Ansible ───────────────────────────────────────────────────────────────
      # Agentless configuration management over SSH. Contrast with Nix: Ansible
      # is imperative per-task; Nix is declarative per-system. You will use both —
      # Nix for machines you own, Ansible for heterogeneous fleets you don't.
      ansible
      ansible-lint

      # ── Pulumi ────────────────────────────────────────────────────────────────
      # IaC in real programming languages (TypeScript, Python, Go, C#). Same cloud
      # provider APIs as Terraform, but expressed as code with full control flow.
      # Strong fit given existing TypeScript familiarity.
      pulumi

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # checkov  # IaC security misconfiguration scanner — add once substantial HCL exists
    ];

  };
}
