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
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.constants;
  values = import ./values.nix;
in
{
  imports = [ ./options.nix ];

  config = {
    cypher-os.constants = {
      username = lib.mkDefault values.username;
      userId = lib.mkDefault 1000;
      displayName = lib.mkDefault "Cypher Whisperer";
      primaryUserShell = lib.mkDefault "zsh";
      homeDirectory = lib.mkDefault values.homeDirectory;
      primaryDisk = lib.mkDefault values.primaryDisk;

      backupRoot = lib.mkDefault "${cfg.homeDirectory}/DATA/FILES";
      obsidianVaultRoot = lib.mkDefault "${cfg.backupRoot}/PROJECTS/PRIVATE/OBSIDIAN_NOTES";

      gamingFiles = {
        root = lib.mkDefault "${cfg.backupRoot}/GAMING";

        steamFiles = {
          root = lib.mkDefault "${cfg.gamingFiles.root}/STEAM_FILES";
          dataRoot = lib.mkDefault "${cfg.gamingFiles.steamFiles.root}/Steam";
          xdgRoot = lib.mkDefault "${cfg.homeDirectoy}/.local/share/Steam";
          steamLibraryRoot = lib.mkDefault "${cfg.gamingFiles.steamFiles.root}/SteamLibrary";
        };
      };

      affineCertificateFile = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/affine/NEW_SCHOOL/PERSISTENT_DATA/caddy/data/caddy/pki/authorities/local/root.crt";
      penpotCertificateFile = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/Penpot/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/caddy/data/caddy/pki/authorities/local/root.crt";

      logseqGraphBaseRoot = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/logseq/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/graph";
    };

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
