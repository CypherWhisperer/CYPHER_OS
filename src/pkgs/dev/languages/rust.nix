# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/rust.nix
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

  config = lib.mkIf (cfg.enable && cfg.rust.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # rustup: the official Rust toolchain manager. Installs rustc, cargo, and
      # the standard library.
      #
      # Manages multiple toolchain versions (stable, beta,  nightly) and targets
      # (for cross-compilation).
      #
      # Usage: rustup toolchain install stable && rustup default stable
      # After install:
      #  - cargo --version
      #  - rustc --version
      #
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: rustup on NixOS requires RUSTUP_HOME and CARGO_HOME to be set.
      # zsh.nix should export:
      #   export RUSTUP_HOME="$HOME/.rustup"
      #   export CARGO_HOME="$HOME/.cargo"
      #   export PATH="$CARGO_HOME/bin:$PATH"
      # ────────────────────────────────────────────────────────────────────────
      rustup
    ];
  };
}
