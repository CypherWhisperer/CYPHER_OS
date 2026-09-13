# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/direnv.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# devenv + direnv work 2gether for per-project declarative development
# environments.
#
# direnv: a shell hook that watches for .envrc files. When you cd into a
#   directory containing .envrc (with `use flake` or `use devenv`), the
#   declared environment activates automatically. cd out — it unloads.
#
# nix-direnv: the Nix-aware backend for direnv. Replaces direnv's naive
#   shell evaluation with a proper nix develop call, with caching so
#   re-entering a directory doesn't re-evaluate the flake from scratch.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.direnv.enable) {
    home.packages = with pkgs; [
      direnv # Per-directory env loading (.envrc); integrates with flakes
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # DIRENV SHELL HOOK.
    # ──────────────────────────────────────────────────────────────────────────
    #
    # programs.direnv.enable wires direnv into the shell so that entering a
    # directory with a .envrc automatically loads its environment.
    #
    # enableNixDirenvIntegration enables `use flake` in .envrc files — meaning
    # per-project devShells activate automatically on `cd`, no `nix develop`
    # needed.
    #
    # This is the recommended workflow for flake-based projects.
    # ──────────────────────────────────────────────────────────────────────────
    # enableNixDirenvIntegration replaces the default direnv stdlib with
    # nix-direnv's, which:
    #   - caches devShell evaluations (fast re-entry)
    #   - keeps shells alive across `nixos-rebuild switch` (GC-safe)
    #   - supports `use flake` and `use devenv` directives in .envrc
    # ──────────────────────────────────────────────────────────────────────────
    programs.direnv = {
      enable = true;
      enableBashIntegration = true; # hooks into bash.
      enableZshIntegration = true; # hook into zsh.
      nix-direnv.enable = true; # this is the key — activates nix-direnv.
    };
  };
}
