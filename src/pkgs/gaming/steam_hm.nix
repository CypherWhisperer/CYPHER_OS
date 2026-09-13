# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/gaming/steam-hm.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Home Manager module for wiring Steam's user-space data directories to their
# canonical locations under:
#   (${cypherOsConstants.backupRoot}/GAMING/STEAM_FILES/)
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
# - Symlinks from ~/.local/share/Steam/{userdata,steamapps} → STEAM_FILES/Steam/
# - A migration activation script that handles the "Steam already created
#   ~/.local/share/Steam/ before HM ran" scenario
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE DOES NOT OWN:
# ──────────────────────────────────────────────────────────────────────────────
#   - programs.steam — that lives in the NixOS system config (./steam-system.nix)
#
#   - The Steam binary, kernel options, udev rules — all system-level
#
#   - SteamLibrary registration — done once in Steam UI > Settings > Storage;
#     Steam persists this in config/libraryfolders.vdf at runtime
#
#   - Game installations — imperative, managed by Steam
#
# ──────────────────────────────────────────────────────────────────────────────
# ARCHITECTURE RATIONALE:
# ──────────────────────────────────────────────────────────────────────────────
#   Steam's data root (~/.local/share/Steam/) contains two categories:
#
#   1. RUNTIME BLOBS — Steam re-downloads and manages these on every update:
#        linux32/, linux64/, ubuntu12_32/, ubuntu12_64/, bin/, package/,
#        bootstrap.tar.xz, steam.sh, *.dll, *.so, steamrt64/, clientui/, etc.
#
#      → We DON"T symlink, back up, or manage these. Steam owns them entirely.
#
#   2. PERSONAL DATA — saves, credentials, and game installs:
#        userdata/   — per-account save data, screenshots, controller profiles
#        steamapps/  — installed games (can be kept here vs in SteamLibrary;
#                      for CypherOS, SteamLibrary is preferred)
#
#      → These are symlinked to STEAM_FILES/Steam/ so they survive reinstalls,
#        are backed up with personal data, and shared across OS lenses.
#
# ──────────────────────────────────────────────────────────────────────────────
# CROSS-OS SHARING (CypherOS context):
# ──────────────────────────────────────────────────────────────────────────────
#   userdata/ and steamapps/ are safe to share across OSs.
#   because they are game data, not OS-specific runtime binaries.
#
#   config/ is intentionally NOT shared — Steam embeds machine context in it
#   and will re-challenge Steam Guard on OS switches if config/ is shared.
#   Let config/ regenerate per OS lens; this is correct behavior.
#
# ──────────────────────────────────────────────────────────────────────────────
# STEAMLIBRARY:
# ──────────────────────────────────────────────────────────────────────────────
#   ${cypherOsConstants.backupRoot}/GAMING/STEAM_FILES/SteamLibrary/ is the
#   secondary game store.
#
#   Register it once: Steam > Settings > Storage > Add Library Folder.
#   Steam writes the path to config/libraryfolders.vdf — no Nix declaration
#   needed. Games installed there are visible to any OS lens that has that
#   path mounted.
#
# ──────────────────────────────────────────────────────────────────────────────
# MIGRATION (first home-manager switch on a machine where Steam has already run):
# ──────────────────────────────────────────────────────────────────────────────
# If ~/.local/share/Steam/ already exists with real content, the activation
# script below will back it up rather than clobber it, then create the symlinks.
# After the switch, inspect the backup and merge userdata/ manually if needed.
#
# ──────────────────────────────────────────────────────────────────────────────
# FIRST-RUN ORDER:
# ──────────────────────────────────────────────────────────────────────────────
#   1. home-manager switch  (creates the symlink structure)
#   2. Launch Steam         (it self-updates into ~/.local/share/Steam/,
#                            finds userdata/ and steamapps/ already symlinked)
#   3. Settings > Storage > Add:
#     ${cypherOsConstants.backupRoot}/GAMING/STEAM_FILES/SteamLibrary/
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.gaming;
  # steamFilesRoot = cypherOsConstants.gamingFiles.steamFiles.root;
  steamDataRoot = cypherOsConstants.gamingFiles.steamFiles.dataRoot;
  steamXdgRoot = cypherOsConstants.gamingFiles.steamFiles.xdgRoot;
  #steamLibraryRoot = cypherOsConstants.gamingFiles.steamFiles.steamLibraryRoot;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.steam.enable) {

    # ──────────────────────────────────────────────────────────────────────────
    # SYMLINKS
    # ──────────────────────────────────────────────────────────────────────────
    # home.file creates a symlink at the HM-managed path pointing to `source`.
    # `recursive = false` (default) means HM creates a single symlink, not a
    # mirror — which is what we want: ~/.local/share/Steam/userdata → our path
    #
    # IMPORTANT: home.file will refuse to overwrite paths that were not
    # created by Home Manager. The activation script below handles
    # pre-existing dirs.
    # ──────────────────────────────────────────────────────────────────────────
    home.file = {
      ".local/share/Steam/userdata" = {
        source = "${steamDataRoot}/userdata";
        # ──────────────────────────────────────────────────────────────────────
        # recursive = false → single symlink (correct)
        # The directory at source must already exist; Steam will populate it.
        # ──────────────────────────────────────────────────────────────────────
      };

      # ────────────────────────────────────────────────────────────────────────
      # uncomment to install games at ~/.local/share/Steam/steamapps/ over
      # ${steamLibraryRoot}
      # ────────────────────────────────────────────────────────────────────────
      #".local/share/Steam/steamapps" = {
      #  source = "${steamDataRoot}/steamapps";
      #};

      ".local/share/Steam/config" = {
        source = "${steamDataRoot}/config";
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # MIGRATION / BOOTSTRAP ACTIVATION.
    # ──────────────────────────────────────────────────────────────────────────
    #
    # Runs during every `home-manager switch`, before the home.file symlinks
    # are applied. Handles two scenarios:
    #
    #   a) Fresh machine: ~/.local/share/Steam/ doesn't exist yet.
    #
    #      → Create the parent dir so Steam can self-populate it on first launch.
    #      → Ensure source directories exist so home.file symlinking succeeds.
    #
    #   b) Steam already ran: ~/.local/share/Steam/userdata or steamapps exist
    #      as real directories (not symlinks).
    #
    #      → Back them up with a timestamp suffix, then remove so HM can create
    #        the symlinks. Merge backed-up data manually afterward.
    # ──────────────────────────────────────────────────────────────────────────
    home.activation.steamDataWiring = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      # ────────────────────────────────────────────────────────────────────────
      # Helpers
      # ────────────────────────────────────────────────────────────────────────
      STEAM_XDG="${steamXdgRoot}"
      STEAM_SRC="${steamDataRoot}"
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)

      # ────────────────────────────────────────────────────────────────────────
      # Ensure the XDG Steam root exists (Steam needs the parent dir present)
      # ────────────────────────────────────────────────────────────────────────
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_XDG"

      # ────────────────────────────────────────────────────────────────────────
      # Ensure our source directories exist (home.file symlink target must exist)
      # ────────────────────────────────────────────────────────────────────────
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/userdata"
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/steamapps"
      ${pkgs.coreutils}/bin/mkdir -p "$STEAM_SRC/config"

      # ────────────────────────────────────────────────────────────────────────
      # Back up and clear any pre-existing real directories
      # ────────────────────────────────────────────────────────────────────────
      # Check: if the path exists AND is not already a symlink → back up.
      # ────────────────────────────────────────────────────────────────────────
      for dir in userdata steamapps config; do
        TARGET="$STEAM_XDG/$dir"
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
          echo "[steam-data] WARNING: $TARGET exists and is not a symlink."
          echo "[steam-data] Backing up to $TARGET.bak-$TIMESTAMP"
          ${pkgs.coreutils}/bin/mv "$TARGET" "$TARGET.bak-$TIMESTAMP"
          echo "[steam-data] Inspect the backup and merge into $STEAM_SRC/$dir if needed."
        fi
      done
    '';
  };
}
