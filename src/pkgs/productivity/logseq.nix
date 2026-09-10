# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/logseq.nix
# ──────────────────────────────────────────────────────────────────────────────
# Sync across devices (e.g., Android phone) is handled at the filesystem layer
# via, say, Syncthing — not by Logseq itself. Syncthing is declared separately.
#
# ──────────────────────────────────────────────────────────────────────────────
# This module:
# ──────────────────────────────────────────────────────────────────────────────
# 1. Installs the Logseq desktop app (with Electron version override to
#    work around the nixpkgs insecure-electron marker on Logseq's pinned
#    version)
#
# 2. Declares where the graph base directory exists (i.e., for backups).
# 3. Manages config.edn and custom.css declaratively via home.file
#
# ──────────────────────────────────────────────────────────────────────────────
# Graph data lives at (see below):
# ──────────────────────────────────────────────────────────────────────────────
# Logseq writes to the graph directory constantly — Home Manager manages only
# the logseq/ subdirectory config files, not the graph content itself.
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
  graphBase = cypherOsConstants.logseqGraphBaseRoot;
in
{
  options = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.logseq.enable) {
    home.packages = with pkgs; [ logseq ];

    # ──────────────────────────────────────────────────────────────────────────
    # ── Graph directory:
    # ──────────────────────────────────────────────────────────────────────────
    # Ensure the graph directory exists. Logseq will populate it on first launch
    # when the path is opedded as a new graph.
    # ──────────────────────────────────────────────────────────────────────────
    home.file."${graphBase}/.keep" = {
      text = "";
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── config.edn:
    # ──────────────────────────────────────────────────────────────────────────
    # Logseq reads logseq/config.edn inside the graph directory. :custom-css-url
    # is overridden by a local custom.css if present — we use local CSS to avoid
    # any outbound network dependency.
    # ──────────────────────────────────────────────────────────────────────────
    home.file."${graphBase}/logseq/config.edn" = {
      text = ''
        {:meta/version 1

         ;; Preferred file format for new pages
         :preferred-format :markdown

         ;; Preferred workflow (todo or now)
         :preferred-workflow :todo

         ;; Journals directory
         :journals-directory "journals"

         ;; Pages directory
         :pages-directory "pages"

         ;; Hide these paths from the file tree
         :hidden []

         ;; Disable telemetry — Logseq respects this flag
         :telemetry-enabled false

         ;; Daily notes template name (set to your Logseq template name if you use one)
         ;; :default-templates {:journals ""}

         ;; Feature flags
         :feature/enable-block-timestamps? false
         :feature/enable-whiteboards? false
        }
      '';
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── custom.css — Catppuccin Mocha:
    # ──────────────────────────────────────────────────────────────────────────
    # Logseq auto-loads logseq/custom.css from the graph directory.
    # Using a local file (not :custom-css-url) avoids any outbound request —
    # consistent with the privacy-first posture.
    #
    # Source: https://logseq.catppuccin.com/ctp-mocha.css
    # Pinned to a local copy so theming works fully offline.
    #
    # To update:
    #  curl \
    #    -o logseq-catppuccin-mocha.css \
    #    https://logseq.catppuccin.com/ctp-mocha.css
    #
    # then embed it here or reference it via a path in the nix store.
    #
    # home.file would place a Nix store symlink here, which Logseq's CSS file
    # watcher cannot follow correctly. home.activation copies the file as a real
    # mutable file instead. Updated on every `home-manager switch`.
    # ──────────────────────────────────────────────────────────────────────────
    home.activation.logseqCatppuccinCss = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD cp --remove-destination \
        ${./config/catppuccin-mocha.css} \
        "${graphBase}/logseq/custom.css"
      $DRY_RUN_CMD chmod 644 "${graphBase}/logseq/custom.css"
    '';
  };
}
