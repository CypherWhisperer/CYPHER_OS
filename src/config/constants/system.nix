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

{ config, lib, ... }:

let
  cfg = config.cypher-os.constants;
in
{
  imports = [ ./options.nix ];

  config = {
    cypher-os.constants = {
      username = lib.mkDefault "cypher_whisperer";
      homeDirectory = lib.mkDefault "/home/cypher-whisperer";
      primaryDisk = lib.mkDefault "/dev/sda";
      stateVersion = lib.mkDefault "24.11";

      backupRoot = lib.mkDefault "${cfg.homeDirectory}/DATA/FILES";
      obsidianVaultRoot = lib.mkDefault "${cfg.backupRoot}/PROJECTS/PRIVATE/OBSIDIAN_NOTES";

      userAvatar = lib.mkDefault ../../de/assets/default-gnome-avatar.jpg;
      defaultWallpaper = lib.mkDefault ../../de/assets/default-gnome-bg.jpg;
    };

    environment.etc."cypher-os/constants.json".text = builtins.toJSON cfg;
  };
}
