# ──────────────────────────────────────────────────────────────────────────────
# src/profile/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# NixOS-context half of the profile module.
#
# On this graph, cypher-os.profile.active / lens.current are the
# authoritative values — set once by the host's own profile.nix. There's
# no osConfig fallback needed here; this IS the source osConfig exposes
# to the nested HM graph.
#
# Exposed via _module.args for symmetry with hm.nix's cypherOsProfile /
# cypherOsLens, so Phase 5's system-side category modules can consume
# them the same way regardless of which graph they're written for.
#
# No profile-conditional defaults live here yet — Phase 5 is what moves
# each category's mkDefault cascade in, kept out of this phase to keep
# the diff reviewable on its own.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  ...
}:
{
  imports = [ ./options.nix ];

  config._module.args = {
    cypherOsProfile = config.cypher-os.profile.active;
    cypherOsLens = config.cypher-os.lens.current;
  };
}
