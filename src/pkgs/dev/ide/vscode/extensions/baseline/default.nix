# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/baseline/default.nix
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
  imports = [
    ../../options.nix
    ./bash.nix
    ./html_css_svg.nix
    ./md.nix
  ];

  config = lib.mkIf (cfg.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        naumovs.color-highlight
        christian-kohler.path-intellisense
        visualstudioexptteam.vscodeintellicode
        visualstudioexptteam.intellicode-api-usage-examples

        # ── Vim keybindings ───────────────────────────────────────────────────
        #vscodevim.vim

        # ──────────────────────────────────────────────────────────────────────
        # YAML support — used by k8s manifests, GH Actions, etc
        # ──────────────────────────────────────────────────────────────────────
        redhat.vscode-yaml

        # ──────────────────────────────────────────────────────────────────────
        # BETTER COMMENTS.
        # ──────────────────────────────────────────────────────────────────────
        aaron-bond.better-comments
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────

        # ── AI / Code Review ──────────────────────────────────────────────────
        vscMkt.coderabbit.coderabbit-vscode
        vscMkt.openai.chatgpt

        # ── AI: Claude Code ───────────────────────────────────────────────────
        vscMkt.anthropic.claude-code

        # ── Code Runner ───────────────────────────────────────────────────────
        vscMkt.formulahendry.code-runner

        # ── Theme ─────────────────────────────────────────────────────────────
        vscMkt.decaycs.decay
        vscMkt.nishantg96.dark-decay-pro
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # YAML.
      # ────────────────────────────────────────────────────────────────────────
      "[yaml]" = {
        "editor.defaultFormatter" = "redhat.vscode-yaml";
      };

      # ────────────────────────────────────────────────────────────────────────
      # JSON.
      # ────────────────────────────────────────────────────────────────────────
      "[json]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };

      # ── Extension: Color Highlight ───────────────────────────────────────────
      "color-highlight.enable" = true;

      # ────────────────────────────────────────────────────────────────────────
      # BETTER COMMENTS
      # ────────────────────────────────────────────────────────────────────────
      "better-comments.tags" = [
        {
          tag = "!";
          color = "#FF2D00";
          strikethrough = false;
          underline = false;
          backgroundColor = "transparent";
          bold = false;
          italic = false;
        }
        {
          tag = "?";
          color = "#3498DB";
          strikethrough = false;
          underline = false;
          backgroundColor = "transparent";
          bold = false;
          italic = false;
        }
        {
          tag = "//";
          color = "#474747";
          strikethrough = true;
          underline = false;
          backgroundColor = "transparent";
          bold = false;
          italic = false;
        }
        {
          tag = "todo";
          color = "#FF8C00";
          strikethrough = false;
          underline = false;
          backgroundColor = "transparent";
          bold = false;
          italic = false;
        }
        {
          tag = "*";
          color = "#98C379";
          strikethrough = false;
          underline = false;
          backgroundColor = "transparent";
          bold = false;
          italic = false;
        }
      ];
    };
  };
}
