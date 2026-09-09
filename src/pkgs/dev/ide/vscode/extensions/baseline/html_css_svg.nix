# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/baseline/html_css_svg.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
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

        # ── Web / HTML / CSS ────────────────────────────────────────────
        ecmel.vscode-html-css
        ritwickdey.liveserver

        # ── SVG ─────────────────────────────────────────────────────────
        jock.svg
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────

        # ── HTML ────────────────────────────────────────────────────────
        vscMkt.george-alisson.html-preview-vscode
        vscMkt.sidthesloth.html5-boilerplate
        vscMkt.riazxrazor.html-to-jsx

        # ── CSS ─────────────────────────────────────────────────────────
        vscMkt.phoenisx.cssvar

        # ── SVG ─────────────────────────────────────────────────────────
        vscMkt.henoc.svgeditor
        vscMkt.sidthesloth.svg-snippets
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      "[html]" = {
        "editor.defaultFormatter" = "vscode.html-language-features";
      };

      "[css]" = {
        "editor.defaultFormatter" = "vscode.css-language-features";
      };

      "[scss]" = {
        "editor.defaultFormatter" = "vscode.css-language-features";
      };
    };
  };
}
