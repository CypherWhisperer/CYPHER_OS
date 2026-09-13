# Infrastructure as Code — `iac.nix`

> Installs IaC tooling: OpenTofu as the primary declarative infrastructure tool, Terragrunt for DRY config composition, tflint and terraform-docs for quality, tenv for version management, Ansible for agentless configuration management, and Pulumi for code-first IaC.

**Module path:** `modules/devops/iac.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Import `./terraform.nix` for optional HashiCorp Terraform installation (gated on `iac.terraform.enable`)
- Install OpenTofu, tenv, tflint, terraform-docs, and Terragrunt when `iac.enable` is true
- Install Ansible and ansible-lint for agentless configuration management
- Install Pulumi for code-first IaC in TypeScript, Python, Go, and other languages

**Does not:**

- Manage Terraform or OpenTofu state files — those belong to a backend (local, S3, Terraform Cloud) and are never committed to this repository
- Store provider credentials — those are injected via environment variables or sops-nix secrets at runtime
- Manage Ansible inventory — that lives in project repositories, not in Nix config

---

## Evaluation Context

| Property              | Value                                                       |
| --------------------- | ----------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                              |
| Options namespace     | `cypher-os.devops.iac.*`                                    |
| Imports `options.nix` | No — imported by `system.nix`                               |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.iac.enable)` |
| Profile default       | `lib.mkDefault true` — enabled by default in the devops profile |

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A top-level `imports` list with a single entry.

**What does it do?** Pulls `./terraform.nix` into the NixOS evaluation context unconditionally. `terraform.nix` itself is gated on `iac.terraform.enable`, so the import is safe even when Terraform is not wanted.

**Why is it here?** Terraform is separated into its own file because it is an optional addition to the IaC stack — HashiCorp changed its license to BSL in 2023, making it a deliberate opt-in rather than a default. Having the module imported here (rather than from `system.nix`) keeps the `iac` subtree self-contained: all IaC-related files are reachable from this file.

```nix
imports = [ ./terraform.nix ];
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents all package installation if either `devops.enable` or `devops.iac.enable` is false.

**Why is it here?** Standard CypherOS pattern.

---

### Block 3 — `environment.systemPackages`

**What is this?** The package list for the IaC toolchain.

**What does it do?** Installs all active IaC tools. Documents `checkov` as DEFERRED.

#### Package inventory

**OpenTofu:**
- `opentofu` — the FOSS fork of Terraform, maintained under the Linux Foundation with the original MPL-2.0 license. Invoked as `tofu`, not `terraform`, to avoid PATH collision when both are installed. HCL syntax is fully compatible with Terraform. Use for all new personal projects.

The Terraform / OpenTofu distinction matters: HashiCorp changed Terraform's license to BSL (Business Source License) in August 2023. BSL restricts use in competing products but does not affect personal or organisational internal use. OpenTofu forked from the last MPL-licensed Terraform release and is the open-source continuation. Both are included in the broader module set (`terraform.nix` handles HashiCorp Terraform) because: you will encounter Terraform in every job and team context; OpenTofu is the open-source default for personal work. The two are functionally identical for all IaC work at the learning stage.

**Version management:**
- `tenv` — version manager for opentofu, terraform, and terragrunt; allows pinning specific tool versions per-project via `.opentofu-version` or `.terraform-version` files; essential when working across multiple projects that require different tool versions

**Linting and documentation:**
- `tflint` — static linter for Terraform/OpenTofu HCL; catches type errors, missing required attributes, and provider-specific rule violations before `tofu apply`; integrates with editor LSP via `efm-langserver` or `null-ls`
- `terraform-docs` — generates documentation tables of variables, outputs, and resources from `.tf` files; produces Markdown suitable for module READMEs

**Composition:**
- `terragrunt` — thin wrapper around Terraform/OpenTofu that adds DRY configuration, remote state management, and module composition across multiple root modules; addresses the problem of copy-pasting provider and backend blocks across many Terraform root modules; learn plain OpenTofu first; reach for Terragrunt when configurations begin to repeat

**Ansible:**
- `ansible` — agentless configuration management and orchestration; describes desired system state in YAML playbooks and applies it over SSH; the practical complement to Nix for heterogeneous infrastructure you don't fully own; NixOS handles machines you control end-to-end; Ansible handles everything else
- `ansible-lint` — linter for Ansible playbooks; catches deprecated syntax, style violations, and common mistakes; best adopted from the start rather than retrofitted

The Nix / Ansible duality: Nix is declarative and reproducible but requires NixOS on the target. Ansible is imperative but works against any Unix system over SSH. In practice you will use both — Nix for machines you own and fully manage, Ansible for cloud VMs, CI runners, and client environments where you cannot control the OS.

**Pulumi:**
- `pulumi` — IaC in real programming languages (TypeScript, Python, Go, C#, Java); compiles down to the same cloud provider APIs as Terraform/OpenTofu but expresses infrastructure as code with loops, conditionals, functions, and type systems; particularly well-suited if TypeScript is already your primary language; `pulumi new typescript && pulumi up` is the full getting-started path

**Deffered**
- `checkov` - static analysis for IaC security misconfigurations. Scans Terraform, Ansible, Kubernetes manifests. Good CI gate. Add when you have substantial IaC code to scan.

##### VERIFY SETUP:
```bash

terraform version
tofu version
ansible --version
pulumi version
tflint --version
```
---

## Dependencies

**Imported files:**
- `./terraform.nix` — optional HashiCorp Terraform installation; gated on `iac.terraform.enable`

**NixOS options set by this file:**
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.opentofu`, `pkgs.tenv`, `pkgs.tflint`, `pkgs.terraform-docs`, `pkgs.terragrunt`
- `pkgs.ansible`, `pkgs.ansible-lint`
- `pkgs.pulumi`

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.iac.enable` | `bool` | `true` (profile default) | Installs full IaC toolchain |
| `cypher-os.devops.iac.terraform.enable` | `bool` | `true` (profile default) | Installs HashiCorp Terraform via `terraform.nix` |

---

## Design Notes

- `tflint` appeared twice in the original source file — once after `tenv`/`terraform-docs` and once under its own heading. This was a copy-paste error with no semantic effect (NixOS deduplicates identical package entries in `environment.systemPackages`) but made the intent unclear. Removed the duplicate in the 2025-05-28 session.
- `checkov` (IaC security misconfiguration scanner) is DEFERRED rather than EXCLUDED. It is a genuinely valuable addition once there is substantial HCL or Ansible code to scan — at that point it becomes a natural CI gate. The deferral is purely about not cluttering the environment before it has a purpose.
- Terraform and OpenTofu coexist cleanly because they use different binary names (`terraform` vs `tofu`). `tenv` can manage versions of both simultaneously.

---

## Known Limitations

- `ansible` on NixOS runs in an isolated Python environment managed by Nix. Installing additional Ansible collections via `ansible-galaxy` may require a writable environment. Use `ansible.cfg` to point `collections_paths` to a user-writable directory outside the Nix store.
- `pulumi` requires language-specific runtimes (Node.js for TypeScript, Python for Python programs, etc.) to be on PATH. These are managed by the `modules/home/dev.nix` Home Manager module, not here.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Terraform module    | `./terraform.nix`            |
| Aggregator          | `./system.nix`               |
| Profile default     | `modules/profile/system.nix` |
