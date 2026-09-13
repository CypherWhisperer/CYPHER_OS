# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/js_ts.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.jsTs.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        christian-kohler.npm-intellisense

        # ── JavaScript / TypeScript ───────────────────────────────────────────
        dbaeumer.vscode-eslint

        # ── Vue / Svelte ──────────────────────────────────────────────────────
        vue.volar # Vue 3 official language support
        svelte.svelte-vscode # Svelte language support

        # ── Mobile: React Native ──────────────────────────────────────────────
        # msjsdiag.vscode-react-native is in marketplace tier (Tier 2)
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────

        # ── JavaScript / TypeScript / React ───────────────────────────────────
        vscMkt.xabikos.javascriptsnippets
        vscMkt.xabikos.reactsnippets
        vscMkt.dsznajder.es7-react-js-snippets
        vscMkt.burkeholland.simple-react-snippets
        vscMkt.ms-vscode.vscode-typescript-next
        vscMkt.jasonnutter.search-node-modules
        vscMkt.infeng.vscode-react-typescript
        vscMkt.msjsdiag.vscode-react-native
        vscMkt.jawandarajbir.react-vscode-extension-pack
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      "[javascript]" = {
        "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
      };
      "[javascriptreact]" = {
        "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
      };
      "eslint.validate" = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
      ];
      "eslint.run" = "onSave";

      # ────────────────────────────────────────────────────────────────────────
      # TypeScript: use workspace version if available, fall back to bundled
      # ────────────────────────────────────────────────────────────────────────
      "typescript.tsdk" = "node_modules/typescript/lib";
      "typescript.enablePromptUseWorkspaceTsdk" = true;

      # ────────────────────────────────────────────────────────────────────────
      # FRAMEWORKS.
      # ────────────────────────────────────────────────────────────────────────
      "[vue]" = {
        "editor.defaultFormatter" = "vue.volar";
      };

      "[svelte]" = {
        "editor.defaultFormatter" = "svelte.svelte-vscode";
      };
    };
  };
}
