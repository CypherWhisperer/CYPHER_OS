# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# generates the JSON read surface at /etc/cypher-os/constants.json
# (per ADR-023 / the constants runbook).
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
