# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/devops/cicd.nix
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

  config = lib.mkIf (cfg.enable && cfg.cicd.enable) {
    environment.systemPackages = with pkgs; [

      # ── GitHub CLI ────────────────────────────────────────────────────────────
      # Official GitHub CLI. Manages PRs, issues, releases, workflow runs, and
      # repository settings from the terminal. The daily driver for GitHub
      # interactions beyond plain git.
      # Authenticate once: gh auth login
      # Core usage: gh pr create, gh pr merge, gh workflow run, gh release create
      gh

      # ── act — local GitHub Actions runner ─────────────────────────────────────
      # Runs GitHub Actions workflows locally using Docker containers that mimic
      # the GitHub runner environment. The fastest way to iterate on .github/
      # workflows/ files without burning CI minutes or waiting for a push.
      #
      # Limitations to know upfront:
      #   - Only supports Linux runners (ubuntu-latest maps to a Docker image)
      #   - systemd is not available inside the containers
      #   - Some actions that rely on GitHub's virtualised runner environment
      #     (e.g. macOS-specific steps) will not run
      #
      # First run: act will ask which runner image size to use (micro/medium/large).
      # The micro image is fastest; use medium/large if actions require more tooling.
      # Store your choice in ~/.actrc: -P ubuntu-latest=catthehacker/ubuntu:act-latest
      #
      # Usage: act                          (run default push event)
      #        act pull_request             (simulate a PR event)
      #        act -j build                 (run a specific job)
      #        act -n                       (dry run — show execution plan)
      #        act --secret-file .secrets   (inject secrets from a file)
      act

      # ── actionlint ────────────────────────────────────────────────────────────
      # Static linter for GitHub Actions workflow YAML files. Catches type errors,
      # undefined context variables, invalid expression syntax, and shell script
      # errors before you push. Integrates with Neovim LSP.
      # Usage: actionlint .github/workflows/ci.yml
      actionlint

      # ── DEFERRED — CI/CD services and extended tooling ────────────────────────
      # github-runner   # self-hosted GitHub Actions runner as a NixOS service
      #                 # deferred: useful once you have workflows that need custom
      #                 # environments or private runners; add via
      #                 # services.github-runners in host configuration

      # gitlab-runner   # GitLab CI/CD runner
      #                 # deferred: add when working with GitLab projects

      # jenkins         # still dominant in enterprise CI/CD
      #                 # deferred: learn GitHub Actions first; Jenkins when needed
      #                 # for an employer context

      # woodpecker-ci   # lightweight self-hosted CI (FOSS Drone fork)
      #                 # deferred: interesting Nix-native CI option — revisit
      #                 # when self-hosting a full CI stack

      # dagger          # portable CI/CD pipelines in code (Go, TypeScript, Python)
      #                 # deferred: overlaps with Pulumi territory; evaluate together
    ];

  };
}
