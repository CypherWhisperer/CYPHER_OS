# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# Sets cypher-os.constants.* defaults and generates the JSON read surface
# at /etc/cypher-os/constants.json (per ADR-023 / the constants runbook).
#
# Dependent constants (backupRoot on homeDirectory, obsidianVaultRoot on
# backupRoot) reference each other via `cfg.*` rather than duplicating —
# this works because Nix's module system resolves mkDefault values
# lazily, so referencing a sibling option's eventual value here is safe
# even though it's also being defined in this same block.
#
# Scripts should read the generated file rather than hardcoding these
# values — see the runbook. Rewriting existing scripts to do so is
# deferred past this phase's verification gate; track separately so it
# isn't silently dropped.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  ...
}:
let
  cfg = config.cypher-os.constants;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = {
    _module.args.cypherOsConstants = cfg;

    # ──────────────────────────────────────────────────────────────────────────
    # System-context read surface: scoped to this lens's own root subvolume, for
    # root-run scripts/systemd units with no reliable $HOME to resolve.
    #
    # See src/config/constants/hm.nix for the cross-lens-shared
    # ~/.config/cypher-os/constants.json equivalent.
    # ──────────────────────────────────────────────────────────────────────────
    environment.etc."cypher-os/constants.json".text = builtins.toJSON cfg;
  };
}
