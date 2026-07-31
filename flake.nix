# flake.nix
#
# Entry point for the cypher-system configuration flake.
#
# A Nix flake is a self-contained, reproducible unit of Nix code with:
#   - inputs:  the external dependencies (nixpkgs version, home-manager version)
#   - outputs: what this flake produces (NixOS systems, Home Manager configs)
#
# The flake.lock file (auto-generated) pins the exact revision of every input.
# This is what makes the config reproducible — running `nixos-rebuild switch`
# six months from now uses the same nixpkgs unless `nix flake update` is explicitly ran.
#
# Adding a new OS host:      add a nixosConfigurations entry.
# Adding a new HM-only host: add a homeConfigurations entry.

{
  description = "CypherOS unified multi-OS configuration flake";

  # ─────────────────────────────────────────────────────────────────────────────
  # INPUTS
  # ─────────────────────────────────────────────────────────────────────────────
  # The external flakes this flake depends on.
  # nixpkgs: the Nix package collection; Has stable and unstable channels,
  # plus overlays for extra packages.

  # Home-manager: follows nixpkgs exactly (same revision) to avoid version skew.
  #   "follows" is a flake deduplication mechanism that says "use the same nixpkgs input
  #   as the parent flake, don't fetch your own copy."
  # Ensures input Flakes and CypherOS all evaluate against the same nixpkgs revision.
  # Without this, Nix would fetch and evaluate a second (possibly different) one.
  inputs = {
    # ─────────────────────────────────────────────────────────────────────────────
    # STABLE CHANNEL
    # ─────────────────────────────────────────────────────────────────────────────
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # ─────────────────────────────────────────────────────────────────────────────
    # UNSTABLE CHANNEL
    # ─────────────────────────────────────────────────────────────────────────────
    # Instead of: nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # You pin to a specific commit where Hydra completed cleanly.
    #
    # To find a good commit:
    #   1. Go to https://hydra.nixos.org/jobset/nixos/unstable/evals
    #   2. Find the latest evaluation where the "tested" column shows ✔
    #      (meaning ALL required test jobs passed)
    #   3. Click it → note the nixpkgs commit hash
    #   4. Paste it here
    #
    # Update periodically (weekly or when a new package version is needed):
    #   nix flake update
    # But only update when SURE Hydra has finished that commit.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      # ────────────────────────  stable channel ────────────────────────────────────
      #url = "github:nix-community/home-manager/release-24.11";
      #url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";

      # ────────────────────────  unstable channel ───────────────────────────────────
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Desktop Linux port.
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-community/nix-vscode-extensions
    # Provides a declarative attrset of virtually every extension on the VS Code
    # Marketplace and Open VSX registry, with pre-computed hashes.
    # This is the escape hatch for extensions not packaged in nixpkgs — no manual
    # sha256 hunting, no hash-mismatch failures at build time.
    # Update all extension hashes in one shot with: nix flake update nix-vscode-extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin/nix — provides a Home Manager module for declarative Catppuccin
    # theming across many applications, including the VSCode extension which
    # pre-compiles the theme at build time (bypassing the read-only store problem
    # that breaks the nixpkgs catppuccin-vsc extension).
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # OUTPUTS
  # ─────────────────────────────────────────────────────────────────────────────
  # A function that receives the resolved inputs and returns an attribute set of
  # everything this flake produces.

  # The @ binding captures ALL inputs into a single attribute set called `inputs`.
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      claude-desktop,
      nix-vscode-extensions,
      catppuccin,
      devenv,
      nur,
      ...
    }@inputs:
    import ./flake { inherit inputs; };
}
