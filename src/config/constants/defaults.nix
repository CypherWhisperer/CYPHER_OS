{
  lib,
  config,
  ...
}:
let
  values = import ./values.nix;
  cfg = config.cypher-os.constants;
in
{
  imports = [ ./options.nix ];

  config.cypher-os.constants = {
    username = lib.mkDefault values.username;
    userId = lib.mkDefault 1000;
    displayName = lib.mkDefault "Cypher Whisperer";
    primaryUserShell = lib.mkDefault "zsh";
    homeDirectory = lib.mkDefault values.homeDirectory;
    primaryDisk = lib.mkDefault values.primaryDisk;
    activeHostName = lib.mkDefault values.activeHostName;

    backupRoot = lib.mkDefault "${cfg.homeDirectory}/DATA/FILES";
    obsidianVaultRoot = lib.mkDefault "${cfg.backupRoot}/PROJECTS/PRIVATE/OBSIDIAN_NOTES";

    gamingFiles = {
      root = lib.mkDefault "${cfg.backupRoot}/GAMING";

      steamFiles = {
        root = lib.mkDefault "${cfg.gamingFiles.root}/STEAM_FILES";
        dataRoot = lib.mkDefault "${cfg.gamingFiles.steamFiles.root}/Steam";
        xdgRoot = lib.mkDefault "${cfg.homeDirectory}/.local/share/Steam";
        steamLibraryRoot = lib.mkDefault "${cfg.gamingFiles.steamFiles.root}/SteamLibrary";
      };
    };

    affineCertificateFile = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/affine/NEW_SCHOOL/PERSISTENT_DATA/caddy/data/caddy/pki/authorities/local/root.crt";
    penpotCertificateFile = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/Penpot/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/caddy/data/caddy/pki/authorities/local/root.crt";

    logseqGraphBaseRoot = lib.mkDefault "${cfg.backupRoot}/DE_FILES/SHARED/APPS/logseq/NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/graph";
  };
}
