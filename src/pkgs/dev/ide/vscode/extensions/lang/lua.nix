# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/lua.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.lua.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────
        sumneko.lua # Lua LSP — essential for CypherIDE config editing
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
      "[lua]" = {
        "editor.defaultFormatter" = "sumneko.lua";
      };

      # Tell the Lua LSP about Neovim's global API so it doesn't flag vim.* as unknown
      "Lua.workspace.library" = [
        "\${3rd}/luv/library" # luv (libuv bindings)
      ];

      "Lua.workspace.checkThirdParty" = false;
      "Lua.diagnostics.globals" = [ "vim" ]; # suppress "undefined global vim"
      "Lua.runtime.version" = "LuaJIT"; # Neovim uses LuaJIT
    };
  };
}
