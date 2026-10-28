# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/libreoffice.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
  homeDir = cypherOsConstants.homeDirectory;

  ctpLO = pkgs.fetchurl {
    # ──────────────────────────────────────────────────────────────────────────
    # Catppuccin Mocha Mauve .soc
    # ──────────────────────────────────────────────────────────────────────────
    url = "https://github.com/catppuccin/libreoffice/raw/main/themes/mocha/mauve/catppuccin-mocha-mauve.soc";
    sha256 = "sha256-c7BIwKlwUpD+rLKQQi43mHi2s/hlNkxPE+eX7iWb2vI=";
  };

  # ──────────────────────────────────────────────────────────────────────────
  # Zotero LibreOffice integration (.oxt), deployed via unopkg.
  # Zotero's own installer scans /opt, which is root-only here (0711), so it
  # fails with NS_ERROR_FILE_ACCESS_DENIED. The .oxt ships inside the Zotero
  # package, so the path follows the Zotero version automatically.
  # ──────────────────────────────────────────────────────────────────────────
  zoteroOxt = "${pkgs.zotero}/lib/integration/libreoffice/Zotero_LibreOffice_Integration.oxt";
  unopkg = "${pkgs.libreoffice}/lib/libreoffice/program/unopkg";
  zoteroExtId = "org.Zotero.integration.openoffice";
  stampDir = "${homeDir}/.local/state/cypher_os";
  stampFile = "${stampDir}/zotero_lo_oxt_stamp";
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.libreOffice.enable) {
    home.packages = with pkgs; [ libreoffice ];

    home.file.".config/libreoffice/4/user/config/catppuccin-mocha-mauve.soc".source = ctpLO;

    # ──────────────────────────────────────────────────────────────────────────
    # LibreOffice on NixOS frequently needs `SAL_USE_VCLPLUGIN=gtk3` set
    # explicitly as an environment variable, otherwise it falls back to its own
    # VCL widget system. Setting the env var forces LibreOffice to use the GTK3
    # rendering backend, at which point it will respect the system's GTK3 theme.
    # ──────────────────────────────────────────────────────────────────────────
    home.sessionVariables = {
      SAL_USE_VCLPLUGIN = "gtk3";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Deploy the Zotero extension into the user's LibreOffice profile.
    # - The stamp file records which .oxt store path was last deployed, so a
    #   Zotero update (new store path) triggers a redeploy.
    # - unopkg needs LibreOffice closed; if it is running, the step is skipped
    #   and the stamp stays stale, so the next switch retries.
    # - Failures never abort the activation; they only print a warning.
    # - unopkg output is captured instead of piped into grep -q, because
    #   pipefail would turn grep's early exit into a false negative.
    # ──────────────────────────────────────────────────────────────────────────
    home.activation.zoteroLibreOfficeExtension = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      stamp="${stampFile}"
      wanted="${zoteroOxt}"
      current=""
      if [ -f "$stamp" ]; then
        current="$(${pkgs.coreutils}/bin/cat "$stamp")"
      fi

      running=0
      if ${pkgs.procps}/bin/pgrep -f soffice >/dev/null 2>&1; then
        running=1
      fi

      if [ "$running" = 1 ]; then
        if [ "$current" != "$wanted" ]; then
          echo "zotero_lo: LibreOffice is running, skipping extension deploy (retry after closing it)" >&2
        fi
      else
        listing="$(${unopkg} list 2>/dev/null || true)"
        case "$listing" in
          *"${zoteroExtId}"*) deployed=1 ;;
          *) deployed=0 ;;
        esac

        if [ "$current" = "$wanted" ] && [ "$deployed" = 1 ]; then
          : # already deployed for this .oxt
        else
          $DRY_RUN_CMD ${unopkg} remove "${zoteroExtId}" >/dev/null 2>&1 || true
          if $DRY_RUN_CMD ${unopkg} add --suppress-license "$wanted" >/dev/null 2>&1; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${stampDir}"
            if [[ ! -v DRY_RUN ]]; then
              printf '%s\n' "$wanted" > "$stamp"
            fi
          else
            echo "zotero_lo: unopkg failed to deploy the Zotero extension" >&2
          fi
        fi
      fi
    '';
  };
}
