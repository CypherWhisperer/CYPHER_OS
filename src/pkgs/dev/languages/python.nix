# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/python.nix
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# PYTHON TOOLING DECISION:
# ──────────────────────────────────────────────────────────────────────────────
# pyenv is explicitly excluded. uv is the recommended default.
# python3 is included as the system interpreter for scripts and tooling.
#
# pyenv: manages Python version installation by compiling from source.
# On NixOS, this conflicts deeply with the Nix store's immutable paths.
#
# pyenv tries to install to ~/.pyenv and link system headers — headers that
# NixOS puts in /nix/store/<hash>-glibc/include, not /usr/include. The
# result is a broken build environment that fights you at every step.
#
# Verdict: DO NOT USE pyenv on NixOS. Use uv or nix shells instead.
#
# uv: Astral's Python package manager (written in Rust). Manages Python
# versions, virtual environments, and package installation in one fast tool.
# Works correctly on NixOS because it uses its own managed Python installs
# rather than trying to compile against system headers.
#
# Verdict: DEFAULT CHOICE. Fast, correct, modern.
#
# nix develop / nix shell: the "pure NixOS" approach. Pin Python version and
# packages declaratively per project. Zero conflicts, fully reproducible.
#
# Steeper learning curve. Consider migrating key projects to this pattern over
# time. Not mutually exclusive with uv for quick scripts.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.languages;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.python.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # python3: the CPython interpreter. Used for scripts, automation,
      # data work, and as the runtime for Python-based tools (ansible, etc.).
      # Note: this is the bare interpreter.
      # For project dependencies, use uv below.
      # ────────────────────────────────────────────────────────────────────────
      python3 # CPython interpreter

      # ────────────────────────────────────────────────────────────────────────
      # uv: Astral's Python package & project manager.
      # ────────────────────────────────────────────────────────────────────────
      # Replaces pip, venv, pipx, and pyenv in one fast (Rust-native) tool.
      #
      # Key operations:
      #   uv python install 3.12    # install a Python version
      #   uv venv                   # create a virtual environment
      #   uv pip install requests   # install into the venv
      #   uv run script.py          # run with the venv active
      #   uv tool install ruff      # install a global CLI tool
      # On NixOS: preferred over pyenv
      # ────────────────────────────────────────────────────────────────────────
      uv

      # ────────────────────────────────────────────────────────────────────────
      # python3Packages.virtualenv: the traditional venv tool. Included as a
      # fallback for scripts and tutorials that explicitly call `virtualenv`
      # rather than `python -m venv` or `uv venv`. Most new code won't need it.
      # ────────────────────────────────────────────────────────────────────────
      python3Packages.virtualenv

      # ────────────────────────────────────────────────────────────────────────
      # Package installer (use venv per project)
      # ────────────────────────────────────────────────────────────────────────
      #python3Packages.pip

      # ────────────────────────────────────────────────────────────────────────
      # install Python CLI tools in isolated envs
      # ────────────────────────────────────────────────────────────────────────
      # NOTE:
      # ────────────────────────────────────────────────────────────────────────
      # disabled 2026-06-06 — pipx 1.8.0 test suite broken at rev 331800de.
      # Re-enable after next `nix flake update` advances nixpkgs past the fix.
      # ────────────────────────────────────────────────────────────────────────
      # pipx
    ];
  };
}
