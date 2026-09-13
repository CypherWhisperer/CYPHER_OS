# HashiCorp Vault (CLI) — `vault.nix`

> _Installs the HashiCorp Vault CLI into the system environment under the `devops.secrets` subsystem._

**Module path:** `modules/devops/vault.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2026-05-29`

---

## Responsibility

**Does:**

- Installs `pkgs.vault` (the Vault CLI binary) into `environment.systemPackages` when both `cypher-os.devops.secrets.enable` and `cypher-os.devops.secrets.vault.enable` are `true`.
- Provides the `vault` binary for interacting with a Vault server — whether local (`vault server -dev`) or remote.

**Does not:**

- Run a Vault server as a NixOS service. The Vault server is run as an OCI container via `virtualisation.oci-containers` elsewhere in the `secrets` module, to work around the unfree derivation issue.
- Declare any `cypher-os.*` options — those live in the parent `secrets` module's `options.nix`.
- Configure Vault namespaces, auth methods, policies, or secrets engines — runtime configuration is the operator's responsibility.

---

## Evaluation Context

| Property              | Value                                                                             |
| --------------------- | --------------------------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                                    |
| Options namespace     | `cypher-os.devops.secrets`                                                        |
| Imports `options.nix` | No — imported by the parent `secrets.nix` aggregator                              |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.secrets.enable && config.cypher-os.devops.secrets.vault.enable)` |
| Profile default       | Set in `modules/profile/system.nix`                                               |

---

## Block Analysis

---

### Block 1 — module signature

**What is this?** The standard NixOS module function signature.

**What does it do?** Brings `config`, `lib`, and `pkgs` into scope. `config` is needed to read `cypher-os.*` options for the kill-switch; `lib` for `mkIf`; `pkgs` for the package set.

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

**What does it do?** When either `cypher-os.devops.secrets.enable` or `cypher-os.devops.secrets.vault.enable` is `false`, this block evaluates to an empty attrset — no packages are added.

**Why is it here?** Two-level guard matches the module hierarchy: the outer flag (`secrets.enable`) controls the entire secrets subsystem; the inner flag (`vault.enable`) allows disabling the Vault CLI specifically without affecting other secrets tooling (`sops-nix`, `age`, `gnupg`) that share the same subsystem.

```nix
config =
  lib.mkIf (config.cypher-os.devops.secrets.enable && config.cypher-os.devops.secrets.vault.enable)
    { ... };
```

---

### Block 3 — `environment.systemPackages` (Vault CLI)

**What is this?** A list passed to the NixOS `environment.systemPackages` option.

**What does it do?** Adds `pkgs.vault` to the system closure, making the `vault` binary available on `PATH` for all users.

**Why is it here?** The Vault CLI is a client tool. The current architecture runs the Vault _server_ as an OCI container (via `virtualisation.oci-containers`) to work around the unfree derivation problem — the CLI binary is still needed to interact with that server. Installing it here means the client is available system-wide without source-building the server binary.

The source build is documented as a fallback path (see Design Notes), but is not the active strategy. The container approach was chosen to avoid build time and RAM pressure on the host.

```nix
environment.systemPackages = with pkgs; [
  vault
];
```

---

## Dependencies

**Imported files:**
- None — this file is imported by `modules/devops/secrets.nix`, which also imports the shared `options.nix`.

**NixOS options set by this file:**
- `environment.systemPackages` — appends `pkgs.vault`.

**nixpkgs packages required:**
- `pkgs.vault` — the HashiCorp Vault CLI. BSL-licensed (≥ 1.15). Requires `nixpkgs.config.allowUnfree = true`. Hydra's last cached build was `vault-1.14.8`; current versions build from source.

**External flake inputs used:**
- None.

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.secrets.enable` | `bool` | `false` | Outer kill-switch for the entire secrets subsystem |
| `cypher-os.devops.secrets.vault.enable` | `bool` | `false` | Installs `pkgs.vault` CLI when `true` alongside the outer switch |

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

- **Vault ≥ 1.15 is BSL/unfree.** Hydra last built `vault-1.14.8`. Current nixpkgs `vault` attribute points to a BSL version and will build from source (Go, so it compiles — but it requires time and RAM). This requires `nixpkgs.config.allowUnfree = true` in the flake config; without it, evaluation fails before the build even starts.
- **Two installation strategies exist; the container approach is active:**
  - _Option 1 — source build:_ `nix build nixpkgs#vault --option max-jobs 1 --option cores 2 --option fallback true --option sandbox true`. Run on an idle machine. Produces a local binary. Requires `allowUnfree`.
  - _Option 2 — OCI container (active):_ The Vault server runs via `virtualisation.oci-containers` elsewhere in the `secrets` module. This file installs only the CLI client, which is smaller and less expensive to build. This is the current architecture.
- **Alternatives to Vault for a purely declarative NixOS workflow:** `bws` (Bitwarden Secrets Manager CLI), `age`, and `sops-nix` are all MPL/Apache-licensed, Hydra-built, and arguably better suited to a declarative NixOS secrets model. Vault is included here for enterprise familiarity and team/production context — learning Vault's concepts (secrets engines, auth methods, policies, leases) is directly applicable to production DevOps environments.
- **Vault key concepts to know:** secrets engines (KV, database, PKI, SSH), auth methods (token, AppRole, Kubernetes), policies and leases. Local dev server: `vault server -dev`. Basic usage: `vault kv put secret/my-app api_key=abc123` / `vault kv get secret/my-app`.

---

## Known Limitations

- `pkgs.vault` builds from source on current nixpkgs because Hydra stopped building it after the BSL license change (last build: `vault-1.14.8`). Source builds require `nixpkgs.config.allowUnfree = true` and consume significant RAM and CPU. Always build on an idle machine.
- No `nixpkgs.config.allowUnfree` guard is in this file itself — the responsibility for setting it lives in the flake's nixpkgs configuration. If it is missing, evaluation of this module will error.
- The split between CLI-in-system-packages and server-in-OCI-container means two separate enable paths exist in the module tree. If the container config is disabled but this file is enabled, the `vault` binary will be present but pointing at no local server.

---

## Related

| Type                   | Reference                                     |
| ---------------------- | --------------------------------------------- |
| Options declared in    | `modules/devops/secrets.nix` (parent aggregator) |
| Imported by            | `modules/devops/secrets.nix`                  |
| Profile default set in | `modules/profile/system.nix`                  |
| Counterpart context    | No `hm.nix` counterpart — CLI tool, system-only |
| Vault server config    | `virtualisation.oci-containers` block in `modules/devops/secrets.nix` |

---

<!-- METADATA
Module:   modules/devops/vault.nix
Context:  NixOS
Created:  2026-05-29
Updated:  2026-05-29
-->
