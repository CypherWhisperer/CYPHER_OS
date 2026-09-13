# CI/CD — `cicd.nix`

> Installs CI/CD tooling for local GitHub Actions development: `gh` (GitHub CLI), `act` (local workflow runner), and `actionlint` (workflow linter).

**Module path:** `modules/devops/cicd.nix`
**Evaluation context:** `NixOS system`
**Status:** `Stable`
**Last reviewed:** `2025-05-28`

---

## Responsibility

**Does:**

- Install `gh` (GitHub CLI) for repository, PR, and workflow management
- Install `act` (nektos/act) for running GitHub Actions workflows locally via Docker
- Install `actionlint` for static linting of workflow YAML files

**Does not:**

- Configure a self-hosted GitHub Actions runner service (`services.github-runners`) — DEFERRED
- Start any persistent service — all three packages are CLI tools only
- Manage GitHub credentials — `gh auth login` handles that interactively

---

## Evaluation Context

| Property              | Value                                                    |
| --------------------- | -------------------------------------------------------- |
| Evaluated by          | `nixosModules`                                           |
| Options namespace     | `cypher-os.devops.cicd.*`                                |
| Imports `options.nix` | No — imported by `system.nix`                            |
| Kill-switch guard     | `lib.mkIf (config.cypher-os.devops.enable && config.cypher-os.devops.cicd.enable)` |
| Profile default       | `lib.mkDefault false` — opt-in                           |

---

## Block Analysis

---

### Block 1 — kill-switch guard

**What is this?** A `lib.mkIf` wrapping the entire `config` attrset.

**What does it do?** Prevents package installation if either `devops.enable` or `devops.cicd.enable` is false.

**Why is it here?** Standard CypherOS kill-switch pattern.

---

### Block 2 — `gh`

**What is this?** A package entry in `environment.systemPackages`.

**What does it do?** Installs the official GitHub CLI. Provides `gh pr`, `gh issue`, `gh workflow`, `gh release`, and `gh repo` subcommands. Authenticate with `gh auth login` (opens a browser flow; stores a token in the system keychain or `~/.config/gh/`).

**Why is it here?** `gh` is the daily-driver interface for GitHub beyond plain `git`. It is especially relevant for CI/CD workflows: `gh workflow run`, `gh workflow view`, and `gh run watch` allow triggering and monitoring Actions runs from the terminal without opening a browser.

---

### Block 3 — `act`

**What is this?** A package entry in `environment.systemPackages`.

**What does it do?** Installs the `act` binary (nektos/act). `act` reads `.github/workflows/` in the current directory, resolves the job dependency graph, and runs jobs in Docker containers that mimic GitHub's runner environment.

**Why is it here?** The feedback loop for GitHub Actions without `act` is: write workflow → commit → push → wait for GitHub CI → read logs. With `act` it is: write workflow → `act -n` (dry run) → `act` (local run). The time saving on a typical workflow iteration is measured in minutes per cycle. It is one of the most immediately high-value CI/CD tools to have installed.

The source comment documents the key limitations (Linux-only runners, no systemd) upfront so they don't surprise you mid-workflow.

---

### Block 4 — `actionlint`

**What is this?** A package entry in `environment.systemPackages`.

**What does it do?** Installs the `actionlint` static analysis tool for GitHub Actions workflow files. Validates expression syntax (`${{ }}` contexts), checks that referenced actions exist, and runs shellcheck on embedded `run:` scripts.

**Why is it here?** YAML workflow files have a non-trivial type system (contexts, expressions, job outputs, matrix values) that is easy to get wrong silently. `actionlint` catches these errors before a push, and integrates with Neovim's LSP via the `efm-langserver` or `null-ls`/`none-ls` approach.

---

## Dependencies

**Imported files:** None directly.

**NixOS options set by this file:**
- `environment.systemPackages`

**nixpkgs packages required:**
- `pkgs.gh`
- `pkgs.act`
- `pkgs.actionlint`

**External flake inputs used:** None

**Runtime dependencies:**
- `act` requires Docker to be running. Enable `cypher-os.devops.containers.enable` or ensure Docker is available from another source.

---

## Option Surface

| Option | Type | Default | Effect when `true` |
|---|---|---|---|
| `cypher-os.devops.enable` | `bool` | `false` | Outer kill-switch |
| `cypher-os.devops.cicd.enable` | `bool` | `false` | Installs `gh`, `act`, `actionlint` |

---

## Design Notes

- This module has no service declarations — all three packages are CLI tools. This makes it the lightest module in the devops subtree: no systemd units, no daemon configuration, no group membership changes.
- `act` has a hard runtime dependency on Docker. This is documented in the source comment but not enforced via NixOS assertions — adding an assertion would create a module-level dependency coupling that seems premature at this stage. A future enhancement could add `lib.mkIf config.virtualisation.docker.enable` around `act` or emit a warning via `lib.warn`.
- `github-runner` (self-hosted runner as a NixOS service) is DEFERRED because it requires a repository token for registration, which is a secret management concern that should be wired through sops-nix. Add it once the sops-nix setup (in `secrets.nix`) is fully activated and the pattern for injecting service secrets is established.

---

## Known Limitations

- `act` only simulates Linux runners. Workflows using `macos-latest` or `windows-latest` cannot be run locally.
- `act` does not support systemd inside containers. Any workflow step that starts or manages systemd services will fail.
- `actionlint` does not validate that referenced action versions (`uses: actions/checkout@v4`) are current — it only validates syntax and expressions.

---

## Related

| Type                | Reference                    |
| ------------------- | ---------------------------- |
| Options declared in | `./options.nix`              |
| Aggregator          | `./system.nix`               |
| Profile default     | `modules/profile/system.nix` |
