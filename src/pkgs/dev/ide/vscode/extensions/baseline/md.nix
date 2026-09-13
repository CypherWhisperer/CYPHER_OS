# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/baseline/md.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  #vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # TOC, list editing, shortcuts
        # ──────────────────────────────────────────────────────────────────────
        yzhang.markdown-all-in-one

        # ──────────────────────────────────────────────────────────────────────
        # Lint enforcement
        # ──────────────────────────────────────────────────────────────────────
        davidanson.vscode-markdownlint

        # ──────────────────────────────────────────────────────────────────────
        # Rich rendering (Mermaid, math, themes)
        # ──────────────────────────────────────────────────────────────────────
        shd101wyy.markdown-preview-enhanced

        # ──────────────────────────────────────────────────────────────────────
        # Mermaid in native preview
        # ──────────────────────────────────────────────────────────────────────
        bierner.markdown-mermaid

        # ──────────────────────────────────────────────────────────────────────
        # Optional: GitHub-styled native preview
        # ──────────────────────────────────────────────────────────────────────
        #bierner.markdown-preview-github-styling
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
    };
  };
}
