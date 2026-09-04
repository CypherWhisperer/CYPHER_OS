# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# HM-context half of the constants module.
# ──────────────────────────────────────────────────────────────────────────────
# Static/derived-invariant constants (such as stateVersion, userAvatar,
# defaultWallpaper, backupRoot, obsidianVaultRoot) already resolve identically
# in this graph via options.nix — no forwarding needed here.
#
# Only the machine-variant three (username, homeDirectory, primaryDisk) actually
# depend on osConfig — see docs/contributing/conventions/constants.md for the
# bucket breakdown and why "machine-variant," not "host-variant."
#
# ──────────────────────────────────────────────────────────────────────────────
# Generates ~/.config/cypher-os/constants.json unconditionally, for  every lens
# including the nested cypher-nixos host — not gated on osConfig, because $HOME
# is a shared subvolume across every lens on this machine.
#
# This is the one genuinely cross-lens-visible read surface: whichever lens
# activates most recently rewrites it, which is idempotent as long as every
# lens's machine-variant values agree — an invariant this file does not itself
# enforce. See constants.md §5.
#
# ──────────────────────────────────────────────────────────────────────────────
# Distinct in purpose from /etc/cypher-os/constants.json (system.nix):
# that copy is scoped to the NixOS lens's own root subvolume, for system-context
# consumers (root-run scripts, systemd units) with no reliable $HOME to resolve.
# Same content, different audience.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  osConfig ? null,
  ...
}:

let
  cfg = if osConfig != null then osConfig.cypher-os.constants else config.cypher-os.constants;
in
{
  imports = [ ./options.nix ];

  config = {
    _module.args.cypherOsConstants = cfg;

    home.file.".config/cypher-os/constants.json".text = builtins.toJSON cfg;
  };
}
