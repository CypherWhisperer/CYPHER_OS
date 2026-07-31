# modules/home/gc-system.nix

{ ... }:

{
  services.home-manager.autoExpire = {
    enable = true;
    # Master switch. false (default) means none of the rest of this
    # block does anything — no timer is created at all.
    # sets up a systemd --user timer that runs `home-manager expire-generations`

    timestamp = "-7 days";
    # Passed straight to `date -d`, so anything that flag accepts works:
    # "-30 days", "-2 weeks", "-1 month", "-7 days". This is the *retention window*
    # — generations older than this get expired (their profile symlink removed)
    # each time the timer fires. Mirrors our nix.gc
    # "--delete-older-than 7d" for parity between system and HM.

    frequency = "weekly";
    # systemd OnCalendar syntax — how often the timer fires.
    # Default is "monthly"; weekly makes more sense paired with a 7-day
    # retention window (monthly would mean up to ~3 weeks of generations
    # accumulate past your intended cutoff between runs).
    # Other valid values: "daily", "Mon *-*-* 03:00:00", etc. — see
    # systemd.time(7).

    store.cleanup = false;
    # If true, runs `nix-collect-garbage` immediately after expiring
    # generations, on top of expiring them. Left false deliberately:
    # CypherOS' system-level `nix.gc` already does store cleanup, so
    # enabling this too means two independent nix-collect-garbage
    # invocations that don't coordinate with each other. Only flip this
    # on if you decide to retire nix.gc entirely and let HM own cleanup
    # for the user profile instead.

    # store.options = "--delete-older-than 30d";
    # Only meaningful if store.cleanup = true above — extra flags
    # passed to the nix-collect-garbage invocation this module runs.
    # Left commented since store.cleanup is off.
  };
}
