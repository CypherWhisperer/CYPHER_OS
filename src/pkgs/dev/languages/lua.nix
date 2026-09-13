# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/lua.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.languages;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.lua.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # LUA.
      # ────────────────────────────────────────────────────────────────────────
      # lua: the Lua interpreter. Required for CypherIDE (Neovim config is
      # written in Lua). Also used in game scripting, Redis scripting, and nginx
      # config. Usage: lua --version   lua script.lua
      # ────────────────────────────────────────────────────────────────────────
      lua
    ];
  };
}
