# Cloud Providers — `cloud.nix`

> Installs cloud provider CLIs and supporting tooling under the `cypher-os.devops.cloud.*` namespace, with independent per-provider enable flags.

**Module path:** `modules/devops/cloud.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Install `awscli2`, `eksctl`, and `aws-vault` when `cloud.aws.enable` is true
- Install `azure-cli` when `cloud.azure.enable` is true
- Install `google-cloud-sdk` when `cloud.gcp.enable` is true
- Document cloud-agnostic tooling (`steampipe`, `infracost`) in DEFERRED comments

**Does not:**

- Store or manage AWS/Azure/GCP credentials (those live in `~/.aws`, `~/.azure`, etc., or injected by `aws-vault` / sops-nix)
- Declare options — see `options.nix`
- Install `awslogs` — the upstream project is unmaintained and incompatible with `awscli2`; `aws logs tail` (built into `awscli2`) replaces it

---

## Evaluation Context

| Property              | Value                                                                      |
| --------------------- | -------------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                             |
| Options namespace     | `cypher-os.devops.cloud.*`                                                 |
| Imports `options.nix` | No — imported by `system.nix`, which imports `options.nix`                 |
| Kill-switch guard     | `lib.mkIf (top.enable && cfg.enable)`                                      |
| Profile default       | `lib.mkDefault false` — not enabled by default; opt-in per host            |

---

## Block Analysis

---

### Block 1 — `let` bindings

**What is this?** Local aliases for the two most-referenced option paths.

**What does it do?** Binds `cfg = config.cypher-os.devops.cloud` and `top = config.cypher-os.devops` to short names, avoiding repetition in every `mkIf` and `optionals` call below.

**Why is it here?** The cloud module has three sub-enable flags (`aws`, `azure`, `gcp`), each of which gates a separate `lib.optionals` block. Without the aliases, every reference would be a full `config.cypher-os.devops.cloud.aws.enable` chain — noisy and error-prone to maintain.

```nix
let
  cfg = config.cypher-os.devops.cloud;
  top = config.cypher-os.devops;
in
```

---

### Block 2 — top-level kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents any package installation if either `cypher-os.devops.enable` or `cypher-os.devops.cloud.enable` is false. The inner `lib.optionals` calls cannot fire if this outer guard is false.

**Why is it here?** Follows the CypherOS kill-switch pattern: the parent enable (`devops`) must be true before any child module contributes packages. This allows disabling the entire devops subtree cleanly from the profile.

```nix
config = lib.mkIf (top.enable && cfg.enable) { ... };
```

---

### Block 3 — `lib.optionals cfg.aws.enable` — AWS packages

**What is this?** A conditional package list gated on `cypher-os.devops.cloud.aws.enable`.

**What does it do?** Adds `awscli2`, `eksctl`, and `aws-vault` to `environment.systemPackages` only when the AWS sub-flag is true. The `++` operator concatenates this list with the Azure and GCP lists regardless of their individual states.

**Why is it here?** AWS, Azure, and GCP are independent learning paths. A user may enable only AWS for months before touching Azure. Per-provider flags make the install surface honest — you don't get Azure CLI build time if you're not using it.

```nix
lib.optionals cfg.aws.enable (with pkgs; [ awscli2 eksctl aws-vault ])
```

---

### Block 4 — `lib.optionals cfg.azure.enable` — Azure packages

**What is this?** Identical structure to Block 3 for the Azure provider.

**What does it do?** Adds `azure-cli` conditionally.

**Why is it here?** `azure-cli` is a large Python application with a significant build footprint. Installing it unconditionally alongside `awscli2` would be wasteful for AWS-only workflows.

```nix
lib.optionals cfg.azure.enable (with pkgs; [ azure-cli ])
```

---

### Block 5 — `lib.optionals cfg.gcp.enable` — GCP packages

**What is this?** Conditional GCP package list.

**What does it do?** Adds `google-cloud-sdk` conditionally.

**Why is it here?** The Google Cloud SDK bundles `gcloud`, `gsutil`, and `bq` in one derivation. It is large and installs a managed Python environment. The NixOS packaging constraint — `gcloud components install` does not work because the installation is managed by Nix — is documented in the source comment so it doesn't surprise the user.

```nix
lib.optionals cfg.gcp.enable (with pkgs; [ google-cloud-sdk ])
```

---

### Block 6 — unconditional cloud-agnostic packages

**What is this?** A `with pkgs;` list appended unconditionally when the top-level `cloud.enable` is true.

**What does it do?** Currently empty (all entries are in DEFERRED comments). Exists as the anchor point for tools that don't belong to a single provider.

**Why is it here?** `steampipe` (SQL over cloud APIs) and `infracost` (cost estimation) are provider-agnostic and deserve their own list rather than being attached to any one provider block.

```nix
++ (with pkgs; [
  # steampipe  # DEFERRED: cross-provider SQL query interface
  # infracost  # DEFERRED: IaC cost estimation
]);
```

---

## Dependencies

**Imported files:** None directly — imported by `system.nix`, which handles `options.nix`.

**NixOS options set by this file:**
- `environment.systemPackages` — per-provider CLI tools

**nixpkgs packages required:**
- `pkgs.awscli2`, `pkgs.eksctl`, `pkgs.aws-vault` (AWS)
- `pkgs.azure-cli` (Azure)
- `pkgs.google-cloud-sdk` (GCP)

**External flake inputs used:** None

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch; must be true for any package to install |
| `cypher-os.devops.cloud.enable` | `bool` | `false` | Activates this module |
| `cypher-os.devops.cloud.aws.enable` | `bool` | `false` | Installs `awscli2`, `eksctl`, `aws-vault` |
| `cypher-os.devops.cloud.azure.enable` | `bool` | `false` | Installs `azure-cli` |
| `cypher-os.devops.cloud.gcp.enable` | `bool` | `false` | Installs `google-cloud-sdk` |

---

## Design Notes

- `lib.optionals` is used instead of separate `mkIf` blocks because the three provider lists compose via `++` into a single `environment.systemPackages` assignment. Separate `mkIf` blocks would require three independent `config` attrsets or `lib.mkMerge`, which is more verbose for the same result.
- `awslogs` is EXCLUDED. The upstream project (`jorgebastida/awslogs`) is unmaintained and its Python dependencies are incompatible with `awscli2`'s boto3 version. CloudWatch log streaming is available via `aws logs tail --follow` in `awscli2` with no additional package.
- `aws-sam-cli` is DEFERRED to the point when Lambda/serverless work begins. It has Docker as a runtime dependency and adds non-trivial build weight.

---

## Known Limitations

- `google-cloud-sdk` on NixOS does not support `gcloud components install`. Additional SDK components must be installed as separate Nix packages.
- `azure-cli` has a large Python dependency closure; first build from source (no binary cache hit) takes several minutes.

---

## Related

| Type                | Reference                                   |
| ------------------- | ------------------------------------------- |
| Options declared in | `./options.nix`                             |
| Aggregator          | `./system.nix`                              |
| Profile default     | `modules/profile/system.nix`                |
