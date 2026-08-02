# Terraform — `terraform.nix`

> _Installs HashiCorp Terraform as an independently toggleable IaC CLI tool under the `devops.iac` subsystem._

**Module path:** `modules/devops/terraform.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2026-05-29`

---

## Responsibility

**Does:**

- Installs `pkgs.terraform` into `environment.systemPackages` when both `cypher-os.devops.iac.enable` and `cypher-os.devops.iac.terraform.enable` are `true`.
- Provides the `terraform` binary as an independently toggleable package, isolated so the option can enable or disable it without affecting any other IaC tooling.

**Does not:**

- Declare any `cypher-os.*` options — those live in the parent `iac` module's `options.nix`.
- Install OpenTofu — that is handled separately elsewhere (`modules/devops/iac.nix`).
- Install `terraform-ls` (the LSP server) — that is delegated to Mason inside CypherIDE, where LSP lifecycle is managed better.
- Configure any Terraform workspace, backend, or provider — runtime configuration is the user's responsibility.

---

## Evaluation Context

| Property              | Value                                                                         |
| --------------------- | ----------------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                                |
| Options namespace     | `cypher-os.devops.iac`                                                        |
| Imports `options.nix` | No — imported by the parent `iac.nix` aggregator                              |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.iac.enable && config.cypher-os.devops.iac.terraform.enable)` |
| Profile default       | Set in `modules/profile/system.nix`                                           |

---

## Block Analysis

---

### Block 1 — module signature

**What is this?** The standard NixOS module function signature: a lambda that accepts the module system's fixed-point arguments.

**What does it do?** Brings `config`, `lib`, and `pkgs` into scope for the rest of the file. `config` is needed to read `cypher-os.*` options for the kill-switch; `lib` for `mkIf`; `pkgs` for the package attribute set.

**Why is it here?** Required by the NixOS module system. Every file evaluated as a NixOS module must be (or resolve to) a function with this shape.

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` expression gating the entire `config` output on two boolean options being simultaneously `true`.

**What does it do?** When either `cypher-os.devops.iac.enable` or `cypher-os.devops.iac.terraform.enable` is `false`, this block evaluates to an empty attrset — no packages are added to the system.

**Why is it here?** Two-level guard matches the module hierarchy: the outer flag (`iac.enable`) controls the whole IaC subsystem; the inner flag (`terraform.enable`) allows disabling Terraform specifically without disabling other IaC tools (OpenTofu, Terragrunt, Ansible, Pulumi) that share the same subsystem. The isolation is intentional — Terraform builds from source due to the BSL license situation, so having a dedicated toggle means you can drop it without touching anything else.

```nix
config =
  lib.mkIf (config.cypher-os.devops.iac.enable && config.cypher-os.devops.iac.terraform.enable)
    { ... };
```

---

### Block 3 — `environment.systemPackages` (Terraform)

**What is this?** A list passed to the NixOS `environment.systemPackages` option, which installs packages system-wide.

**What does it do?** Adds `pkgs.terraform` to the system closure, making the `terraform` binary available on `PATH` for all users.

**Why is it here?** Terraform is a CLI tool — it runs, does its work (plan/apply), and exits. Installing it system-wide is appropriate; there is no benefit to containerizing a CLI tool on a developer workstation. Despite the BSL license change, the Terraform ecosystem (providers, modules, tutorials) remains the dominant reference in DevOps contexts, so having the real `terraform` binary available is justified alongside OpenTofu. The isolation in its own file means the overnight source build cost (Terraform ≥ 1.6 requires building from source; no Hydra binary exists) is paid once and the toggle exists to drop it cleanly if needed.

```nix
environment.systemPackages = with pkgs; [
  terraform
];
```

---

### Block 4 — `DEFERRED` comment: `terraform-ls`

**What is this?** A commented-out package entry with a `DEFERRED` header explaining where the package should be installed instead.

**What does it do?** Nothing at runtime — it is inactive. It documents that `terraform-ls` (the Terraform Language Server) is intentionally absent from this file.

**Why is it here?** `terraform-ls` provides LSP completion and validation in Neovim. Managing LSP servers via Mason inside CypherIDE keeps LSP lifecycle (install, update, path injection) co-located with the editor config rather than scattered across system packages. The comment prevents the package from being re-added here in the future without understanding why it was excluded.

```nix
# ── DEFERRED ──────────────────────────────────────────────────────────────
# terraform-ls: Terraform Language Server (LSP). Gives completion and
# validation in Neovim. Install via mason.nvim in your CypherIDE config
# rather than here — mason handles LSP server lifecycle better.
# terraform-ls
```

---

## Dependencies

**Imported files:**
- None — this file is imported by `modules/devops/iac.nix`, which also imports the shared `options.nix`.

**NixOS options set by this file:**
- `environment.systemPackages` — appends `pkgs.terraform`.

**nixpkgs packages required:**
- `pkgs.terraform` — HashiCorp Terraform CLI. BSL-licensed (≥ 1.6). Requires `nixpkgs.config.allowUnfree = true`. Hydra's last cached binary was `terraform-1.5.7` (September 2023); current versions build from source.

**External flake inputs used:**
- None. `terraform` is in nixpkgs (unfree).

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.iac.enable` | `bool` | `false` | Outer kill-switch for the entire IaC subsystem |
| `cypher-os.devops.iac.terraform.enable` | `bool` | `false` | Installs `pkgs.terraform` when `true` alongside the outer switch |

---

## Comment Convention

Inline comments in source files use three header tiers to classify non-active code without explanation bloat. Deep rationale belongs here in the documentation, not in the source file.

```nix
# ── DEFERRED — not yet needed; low friction to add ───────────────────────────
# package-name  # reason: <one line>

# ── EXCLUDED — active decision not to include ────────────────────────────────
# package-name  # reason: BSL license / broken nixpkgs derivation / etc.

# ── PENDING — blocked on something external ──────────────────────────────────
# package-name  # blocked on: <what>
```

---

## Design Notes

- **Terraform is BSL-licensed (≥ 1.6), but deliberately installed.** Hydra's last successful build was `terraform-1.5.7` (September 2023 — the last MPL-licensed version before the BSL switch). No binary for any Terraform ≥ 1.6 will ever appear on `cache.nixos.org`. This means installing the current `pkgs.terraform` always requires a source build. This cost was paid in a single overnight session. The `terraform.enable` toggle exists precisely so this cost can be avoided on machines where it is not needed, and so the package can be dropped cleanly without touching any other IaC tooling.
- **OpenTofu exists separately.** OpenTofu is the Linux Foundation fork of Terraform at the 1.5.x branch point — CLI-compatible (`tofu` replaces `terraform`; all `.tf` files work as-is), MPL 2.0 licensed, and built by Hydra with binaries on `cache.nixos.org`. It is handled elsewhere in the IaC module stack. This file is not the OpenTofu install; it is the isolated Terraform install kept for the cases where the real `terraform` binary is specifically needed (provider ecosystem, tutorials, team contexts that haven't migrated).
- **Why not containerize Terraform?** Terraform is a CLI tool — it runs, produces output, and exits. Containerizing a CLI tool on a developer workstation adds overhead with zero benefit. CI pipelines containerize it for environment isolation; that use case does not apply here.
- **Why keep both?** The Terraform ecosystem (providers, modules, job context, tutorials) is still overwhelmingly built around the `terraform` binary. HCL syntax. Despite the license change, you will encounter it in DevOps contexts. Having both lets you work natively in either.
- **Source build command (for reference):** `nix build nixpkgs#terraform --option max-jobs 1 --option cores 2 --option fallback true --option sandbox true`. Requires `nixpkgs.config.allowUnfree = true`. Run on an idle machine.
- **`terraform-ls` is DEFERRED** to Mason inside CypherIDE. See Block 4.
- **Migration path to OpenTofu (if dropping Terraform later):** replace `terraform` with `tofu` in all commands; run `tofu init` to re-download providers; run `tofu providers lock` to regenerate `.terraform.lock.hcl` with OpenTofu-compatible hashes. Everything else is identical.

---

## Known Limitations

- `pkgs.terraform` builds from source on any current nixpkgs revision because Hydra stopped caching it after the BSL license change (last binary: `terraform-1.5.7`). Requires `nixpkgs.config.allowUnfree = true` — if that is missing, evaluation fails before any build starts.
- The source build is expensive in time and RAM. The `terraform.enable` toggle exists specifically to make this cost opt-in per host.
- The `DEFERRED` `terraform-ls` package means no system-level LSP binary is provided. If CypherIDE's Mason config does not install `terraform-ls`, Neovim will have no Terraform language intelligence.

---

## Related

| Type                   | Reference                                      |
| ---------------------- | ---------------------------------------------- |
| Options declared in    | `modules/devops/iac.nix` (parent aggregator)   |
| Imported by            | `modules/devops/iac.nix`                       |
| Profile default set in | `modules/profile/system.nix`                   |
| Counterpart context    | No `hm.nix` counterpart — CLI tool, system-only |
| ADR                    | See Design Notes (Terraform vs OpenTofu coexistence) |

---

<!-- METADATA
Module:   modules/devops/terraform.nix
Context:  NixOS
Created:  2026-05-29
Updated:  2026-05-29
-->
