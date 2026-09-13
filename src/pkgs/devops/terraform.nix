# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/terraform.nix
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

  config = lib.mkIf (cfg.enable && cfg.iac.enable && cfg.iac.terraform.enable) {
    environment.systemPackages = with pkgs; [
      # ── Terraform ─────────────────────────────────────────────────────────────
      # The industry-standard IaC tool. You will encounter this everywhere in
      # DevOps job contexts. HCL (HashiCorp Configuration Language) syntax.
      # Despite the license change, the ecosystem (providers, modules, tutorials)
      # is still overwhelmingly built around Terraform.
      # Usage: terraform init && terraform plan && terraform apply
      #
      terraform

      # ── DEFERRED ──────────────────────────────────────────────────────────────
      # terraform-ls: Terraform Language Server (LSP). Gives completion and
      # validation in Neovim. Install via mason.nvim in your CypherIDE config
      # rather than here — mason handles LSP server lifecycle better.
      # terraform-ls
    ];
  };
}
