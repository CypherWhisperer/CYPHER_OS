# ──────────────────────────────────────────────────────────────────────────────
# src/system/nix_settings.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # NIX SETTINGS
  # ────────────────────────────────────────────────────────────────────────────
  # experimental-features: flakes and nix-command are not yet stable API in Nix,
  # so they're gated behind this flag. You need both enabled to use flakes.
  # nix-command is the unified `nix` CLI (nix build, nix run, nix shell, etc.).
  # ────────────────────────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # ────────────────────────────────────────────────────────────────────────
      # trusted-users allows specified user(s) to run nix as a trusted user —
      # necessary for `home-manager switch` to work with the multi-user daemon.
      # ────────────────────────────────────────────────────────────────────────
      trusted-users = [
        "root"
        "cypher_whisperer"
      ];

      # ────────────────────────────────────────────────────────────────────────
      # ── Build resource ceiling:
      # ────────────────────────────────────────────────────────────────────────
      # max-jobs: how many derivations Nix builds IN PARALLEL.
      # Default is "auto" which means one per CPU core. Setting to 2 means at
      # most 2 derivations build simultaneously.
      #
      # 2 parallel jobs × 2 cores each = 4 cores max during any build.
      # Leaves 4 coreds headroom for GNOME + system processes.
      # NOTE: Update accordingly. Tune accordingly (max-jobs=4, cores=4)
      #       according to specific hardware specs
      # e.g for 16GB+, bump both to 4.
      # ────────────────────────────────────────────────────────────────────────
      max-jobs = 2;

      # ────────────────────────────────────────────────────────────────────────
      # cores: how many CPU cores each individual build job may use.Nix passes
      # this as $NIX_BUILD_CORES to the builder. Setting to 2 means each job
      # gets 2 cores max, so worst case: 2 jobs × 2 cores = 4 cores in use,
      # leaving headroom for, say, a DE/WM.
      # ────────────────────────────────────────────────────────────────────────
      cores = 2;

      # ────────────────────────────────────────────────────────────────────────
      # ── Binary cache:
      # ────────────────────────────────────────────────────────────────────────
      # substituters: where Nix looks for pre-built binaries. Explicitly
      # declaring cache.nixos.org and a trusted public key ensures it's always
      # consulted even in edge cases. On nixos-unstable the cache lags —
      # packages built in the last few hours may not have a substitute yet,
      # triggering a source build.
      # ────────────────────────────────────────────────────────────────────────
      substituters = [
        "https://cache.nixos.org" # Official Hydra cache — free packages only
        "https://nix-community.cachix.org" # Community packages — nix-community CI
        "https://nixpkgs-terraform.cachix.org" # Pre-built terraform BSL binaries

        # ──────────────────────────────────────────────────────────────────────
        # Garnix — builds nixpkgs aggressively, great coverage on nixos-unstable
        # commits
        # ──────────────────────────────────────────────────────────────────────
        # NOTE: DROPPED SINCE garnix.io DROPPED ITS SERVICE.
        # ──────────────────────────────────────────────────────────────────────
        #"https://cache.garnix.io"
        # ──────────────────────────────────────────────────────────────────────
      ];

      # ────────────────────────────────────────────────────────────────────────
      # ── Trusted public keys:
      # ────────────────────────────────────────────────────────────────────────
      # These are Ed25519 PUBLIC keys published by each cache operator.
      # Security model: anyone can host a cache server, but Nix won't install
      # anything from it unless it's signed by a key you explicitly declare here.
      # These keys are published on each operator's docs/website — not secret.
      #
      # IMPORTANT: Keys are bit-for-bit exact. A single wrong character means
      # every package from that cache falls back to a source build silently.
      # Verify each key against the operator's official documentation.
      #
      # cache.nixos.org key:   https://nixos.org/manual/nix/stable/
      # nix-community key:     https://app.cachix.org/cache/nix-community
      # garnix key:            https://garnix.io/docs/caching
      # ────────────────────────────────────────────────────────────────────────
      trusted-public-keys = [
        # ──────────────────────────────────────────────────────────────────────
        # The official NixOS cache key.
        # ──────────────────────────────────────────────────────────────────────
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

        # ──────────────────────────────────────────────────────────────────────
        # nix-community key — verify this matches
        # https://app.cachix.org/cache/nix-community
        # ──────────────────────────────────────────────────────────────────────
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

        "nixpkgs-terraform.cachix.org-1:GYPxe7A0BDFmQ0N3UBPwNtSBffFGhS0TkpJFnVBp2JA="

        # ──────────────────────────────────────────────────────────────────────
        # Garnix public key — from https://garnix.io/docs/caching
        #"cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        # ──────────────────────────────────────────────────────────────────────
      ];

      # ────────────────────────────────────────────────────────────────────────
      # ── Substitute-or-fail:
      # ────────────────────────────────────────────────────────────────────────
      # Do NOT silently fall back to a source build on cache miss or network
      # error. Forces an explicit decision when a binary isn't cached yet.
      #
      # Instead of silently falling into a RAM-crushing source build on cache
      # miss, Nix will hard-error and tell which package has no substitute.
      # Then you make an explicit decision.
      #
      # To override for a specific rebuild when you're ready to let it build:
      #   sudo nixos-rebuild switch --flake .#nixos-gnome --option fallback true
      #
      # This is the "tell me, don't surprise me" setting.
      # ────────────────────────────────────────────────────────────────────────
      fallback = false;

      # ────────────────────────────────────────────────────────────────────────
      # Store Optimization
      # ────────────────────────────────────────────────────────────────────────
      # Deduplicates identical files in /nix/store
      # Saves space without deleting anything
      # ────────────────────────────────────────────────────────────────────────
      auto-optimise-store = true;
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── Build daemon scheduling:
    # ──────────────────────────────────────────────────────────────────────────
    # Runs the Nix daemon at idle CPU and I/O priority. Builds happen in the
    # background without competing with DE sessions for responsiveness.
    #
    # Deprioritises the Nix daemon for both CPU and disk I/O.
    # Builds proceed in the background without competing with active session.
    #
    # daemonCPUSchedPolicy: runs the Nix build daemon at a lower CPU scheduling
    # priority (idle = only runs when nothing else wants the CPU).
    # "idle" is aggressive throttling — good for keeping the DE responsive.
    # "batch" is a softer alternative if idle feels too slow on a quiet machine.
    # ──────────────────────────────────────────────────────────────────────────
    daemonCPUSchedPolicy = "idle";

    # ──────────────────────────────────────────────────────────────────────────
    # daemonIOSchedClass: same idea but for disk I/O. The build daemon won't
    # starve your DE's disk reads during a build.
    # ──────────────────────────────────────────────────────────────────────────
    daemonIOSchedClass = "idle";

    # ──────────────────────────────────────────────────────────────────────────
    # Nix Garbage Collection (GC)
    # ──────────────────────────────────────────────────────────────────────────
    gc = {
      # ────────────────────────────────────────────────────────────────────────
      # Optional: Extra Safety for Dev
      # ────────────────────────────────────────────────────────────────────────
      # This disables automatic GC entirely.
      # You will need to manually run:
      #   nix-collect-garbage -d
      # Useful when you want FULL control over what gets deleted.
      # Keep as false for heavy experimentation
      # ────────────────────────────────────────────────────────────────────────
      automatic = false; # if true: Run GC automatically via systemd timer

      # ────────────────────────────────────────────────────────────────────────
      # Frequency: "daily", "weekly", or cron syntax
      # ────────────────────────────────────────────────────────────────────────
      #dates = "weekly";

      # ────────────────────────────────────────────────────────────────────────
      # Retention policy:
      # Keep anything newer than 7 days.
      # This gives you a rollback window during active development.
      # ────────────────────────────────────────────────────────────────────────
      options = "--delete-older-than 7d";

      # ────────────────────────────────────────────────────────────────────────
      # Optional: Protect Against Accidental Pruning
      # ────────────────────────────────────────────────────────────────────────
      # You can create GC roots manually for critical builds:
      #   nix-store \
      #   --add-root /nix/var/nix/gcroots/my-safe-system \
      #   --realise <drv>
      #
      # Anything referenced by a GC root is NEVER deleted.
      # ────────────────────────────────────────────────────────────────────────
    };
  };
}
