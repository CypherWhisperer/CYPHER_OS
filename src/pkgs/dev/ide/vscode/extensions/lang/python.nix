# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/python.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.python.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        njpwerner.autodocstring
        batisteo.vscode-django
        wholroyd.jinja
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
        vscMkt.donjayamanne.python-environment-manager
        vscMkt.kevinrose.vsc-python-indent
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      "[python]" = {
        "editor.defaultFormatter" = "ms-python.python";
        "editor.tabSize" = 4;
        "editor.formatOnSave" = true;
      };
      "python.analysis.typeCheckingMode" = "basic";
      "python.analysis.autoImportCompletions" = true;
      "python.terminal.activateEnvironment" = true;
    };
  };
}
