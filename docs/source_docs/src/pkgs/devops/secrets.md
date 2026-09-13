# Secrets Management — `secrets.nix`

> Configures the secrets management toolchain: sops-nix integration (blocked on flake input activation), and installs SOPS, age, gnupg, and bws for encrypting, decrypting, and injecting secrets at runtime.

**Module path:** `modules/devops/secrets.nix`
**Evaluation context:** `NixOS system`
**Status:** `In Development` — sops-nix activation is PENDING flake input setup
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Import `./vault-contained.nix` and `./vault.nix` for Vault-related configuration
- Provide a commented-out `sops` configuration block ready to activate once `sops-nix` is added to `flake.nix`
- Install `sops`, `age`, `gnupg`, and `bws` as system packages

**Does not:**

- Store secrets — encrypted files live in the repository; decrypted values are written to `/run/secrets/` at activation time and never committed
- Manage private keys — those are generated once and stored outside the Nix store (`~/.config/sops/age/keys.txt`)
- Install or configure Vault — that is delegated to `vault-contained.nix` and `vault.nix`
- Install `mkcert` — reclassified to `networking.nix` in the 2025-05-28 session; TLS certificates are transport layer infrastructure, not application secrets

---

## Evaluation Context

| Property              | Value                                                            |
| --------------------- | ---------------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                                   |
| Options namespace     | `cypher-os.devops.secrets.*`                                     |
| Imports `options.nix` | No — imported by `system.nix`                                    |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.secrets.enable)` |
| Profile default       | `lib.mkDefault true` — enabled by default in the devops profile  |

---

## Block Analysis

---

### Block 1 — `imports`

**What is this?** A top-level `imports` list delegating Vault configuration.

**What does it do?** Pulls `vault-contained.nix` (OCI container declaration for Vault) and `vault.nix` (Vault-related options and service configuration) into the NixOS evaluation context.

**Why is it here?** Vault is a sub-concern of secrets management but complex enough to warrant its own files. Importing from `secrets.nix` keeps the secrets subtree self-contained: all files reachable from this module are secrets-related. Contrast with `iac.nix`'s approach of importing `terraform.nix` — the same pattern applied consistently.

```nix
imports = [
  ./vault-contained.nix
  ./vault.nix
];
```

---

### Block 2 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents all configuration and package installation if either `devops.enable` or `devops.secrets.enable` is false.

**Why is it here?** Standard CypherOS pattern.

---

### Block 3 — `sops` configuration block (commented out)

**What is this?** A fully-formed `sops.*` configuration block, currently commented out.

**What does it do?** When uncommented, it configures the sops-nix NixOS module to decrypt secrets at system activation time. Sets `defaultSopsFile` to the repository's primary secrets file, `age.keyFile` to the private key path, and `age.generateKey = false` (key generation is manual, not automatic — see why below). _NOTE: `defaultSopsFile` is the default encrypted secrets file, however,Individual secret declarations can override this per-secret if needed. age.keyFile is where sops finds your private age key at activation time. This path must exist on the machine — it's not managed by Nix (intentionally)._
**Why is it commented out?** The `sops.*` NixOS options are provided by the `sops-nix` flake input, which must be added to `flake.nix` and imported into the host configuration before these options exist. Using them without the import causes an "undefined option" evaluation error. The block is left in place — not deleted — so that activation is a single uncomment operation once the flake input is wired.

**Why `age.generateKey = false`?** If NixOS auto-generated the age key, the public key would be unknown until the first system activation — but encrypting secrets requires the public key before activation. This is a chicken-and-egg problem. The key is generated manually once, the public key is noted and added to `.sops.yaml`, and then secrets can be encrypted before any rebuild.

**The sops-nix encryption chain:**
```
plaintext secret
  → encrypted with your age public key
  → committed to git as an encrypted .yaml/.json file
  → decrypted by sops-nix at `nixos-rebuild switch` time
  → written to /run/secrets/<name> with correct permissions
  → application reads /run/secrets/<name> at runtime
```

The critical property: decrypted values land in `/run/secrets/` (a `tmpfs`, cleared on reboot), never in the Nix store (which is world-readable and immutable). This is the correct secrets pattern for NixOS.

```nix
# sops = {
#   defaultSopsFile  = ../../secrets/secrets.yaml;
#   age.keyFile      = "/home/cypher-whisperer/.config/sops/age/keys.txt";
#   age.generateKey  = false;
# };
```

#### EXTRA: SOPS-NIX WORKFLOW:
```bash
# sops-nix integrates SOPS (Secrets OPerationS) into NixOS so secrets are
# decrypted at system activation and made available as files under /run/secrets/.

# The encryption chain:
#  plaintext secret
#       → encrypted with your age public key (or GPG key)
#       → committed to git as an encrypted .yaml/.json file
#       → decrypted by sops-nix at `nixos-rebuild switch` time
#       → written to /run/secrets/<name> with correct permissions

# Your app reads from /run/secrets/<name>, never from the Nix store
# (which is world-readable). This is the correct pattern for NixOS secrets.

# FIRST-TIME SETUP (one-time, manual):
# 1. Generate an age key:
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Note the public key printed to stdout — you need it for .sops.yaml

# 2. Create a .sops.yaml at the root of your repo (e.g CypherOS):
#   creation_rules:
#     - path_regex: secrets/.*\.yaml$
#       age: >-
#         <your-age-public-key-here>

# 3. Create and edit a secret:
mkdir -p secrets
sops secrets/my-secret.yaml
# This opens your editor with an empty YAML file.
# Add key: value pairs. Save and quit — sops encrypts automatically.

# 4. Reference the secret in a NixOS module:
# sops.secrets.my_api_key = {
#   sopsFile = ../../secrets/my-secret.yaml;
# };

# Then in your app config:
# environment.variables.MY_API_KEY = config.sops.secrets.my_api_key.path;
# (path = /run/secrets/my_api_key — the decrypted file at runtime)
```
---

### Block 4 — `environment.systemPackages`

**What is this?** The package list for secrets management tooling.

**What does it do?** Installs `sops`, `age`, `gnupg`, and `bws`. Documents `agenix` as DEFERRED.

#### Package inventory

**SOPS:**
- `sops` — Secrets OPerationS; the primary CLI for encrypting and decrypting secret files; supports age, GPG, AWS KMS, GCP KMS, and Azure Key Vault backends; for self-hosted use, the age backend is the simplest and has no dependency on key servers; edit secrets in-place with `sops secrets/my-secret.yaml` (encrypted on save); decrypt to stdout with `sops -d secrets/my-secret.yaml`

**age:**
- `age` — modern file encryption tool; simpler than GPG with no key server required; used as the SOPS encryption backend in this setup; `age-keygen` generates key pairs; `age -r <recipient-pubkey>` encrypts; `age -d -i key.txt` decrypts; the generated key file at `~/.config/sops/age/keys.txt` must never be committed to git or the Nix store

**gnupg:**
- `gnupg` — the GPG implementation; kept alongside age because GPG serves use cases beyond SOPS: signing git commits (`git config --global commit.gpgsign true`), verifying signed package releases and binaries, and as a SOPS backend for teams that already use GPG infrastructure; the recommendation is: use age for SOPS, use gnupg for git signing and package verification

**Bitwarden Secrets Manager CLI:**
- `bws` — CLI for Bitwarden Secrets Manager (machine secrets, distinct from the Bitwarden password vault); a lighter-weight alternative to Vault for injecting secrets into scripts and CI pipelines without full Vault policy infrastructure; aligns with the Proton ecosystem boundary — use for secrets that don't need Vault's access control model

---

## Dependencies

**Imported files:**
- `./vault-contained.nix` — OCI container declaration for HashiCorp Vault
- `./vault.nix` — Vault-related NixOS options and configuration

**NixOS options set by this file:**
- `sops.*` — PENDING flake input activation (currently commented out)
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.sops`, `pkgs.age`, `pkgs.gnupg`, `pkgs.bws`

**External flake inputs used:**
- `sops-nix` — PENDING; must be added to `flake.nix` inputs before the `sops.*` block can be uncommented

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.secrets.enable` | `bool` | `true` (profile default) | Activates this module; installs toolchain |
| `cypher-os.devops.secrets.vault.enable` | `bool` | `true` (profile default) | Enables Vault via `vault-contained.nix` / `vault.nix` |

---

## Design Notes

- `mkcert` was removed from this module in the 2026-05-28 session. It generates locally-trusted TLS certificates — transport layer infrastructure, not application secrets. It now lives in `networking.nix` alongside Caddy and Traefik, which consume those certificates.
- The sops-nix activation path is deliberately left incomplete here rather than blocking the whole module. The toolchain (`sops`, `age`, `gnupg`) is immediately useful for manual encryption operations, git commit signing, and learning the SOPS workflow, even before the NixOS integration is active.
- `agenix` (an alternative to sops-nix) is DEFERRED pending a firm commitment to sops-nix as the secrets path. Having both active would be redundant. If sops-nix proves cumbersome, revisit agenix — it has a simpler mental model at the cost of less flexibility.

---

## Known Limitations

- The `sops.*` configuration block is entirely inert until `sops-nix` is added to `flake.nix` and imported in the host configuration. See the sops-nix activation runbook.
- `gnupg` on NixOS uses a pinentry program for passphrase entry. The correct pinentry variant for a GNOME + Wayland environment is `pinentry-gnome3`. If GPG operations hang waiting for a passphrase, ensure the gpg-agent is configured with the right pinentry in `~/.gnupg/gpg-agent.conf`.

---

## Related

| Type                    | Reference                    |
| ----------------------- | ---------------------------- |
| Options declared in     | `./options.nix`              |
| Vault OCI container     | `./vault-contained.nix`      |
| Vault NixOS config      | `./vault.nix`                |
| Aggregator              | `./system.nix`               |
| `mkcert` moved to       | `./networking.nix`           |
| Profile default         | `modules/profile/system.nix` |
| sops-nix activation     | `docs/runbooks/sops-nix-activation.md` _(pending)_ |
