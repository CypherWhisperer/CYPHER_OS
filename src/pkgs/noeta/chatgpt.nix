# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/chatgpt.nix
# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────
# NOTE: chatgpt dropped (toggled off) since its currently only supports
# {aarch64,x86_64}-darwin, hence it doesn't work on Linux
# ──────────────────────────────────────────────────────────────────────────────
# error:
# Refusing to evaluate package 'chatgpt-26.803.81509' in 
# /nix/store/jr0crp0if9q7yxisyzx7nzx53ay7p2bz-source/pkgs/by-name/ch/chatgpt/package.nix:40
# because it is not available on the requested hostPlatform:
#
# hostPlatform.system = "x86_64-linux"
#   package.meta.platforms = [
#   "aarch64-darwin"
# ]
# package.meta.badPlatforms = [ ]
# 
# a) To temporarily allow packages that are unsupported for this system,
#    you can use an environment variable for a single invocation of the
#    nix tools: `$ export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1`
# 
#    Note: When using `nix shell`, `nix build`, `nix develop`, etc with
#    a flake, then pass `--impure` in order to allow use of environment
#    variables.
# 
# b) For `nixos-rebuild` you can set:
#      { nixpkgs.config.allowUnsupportedSystem = true; }
#    in configuration.nix to override this.
# 
# c) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you
#    can add { allowUnsupportedSystem = true; } to
#    ~/.config/nixpkgs/config.nix.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.chatgptCli.enable) {
      home.packages = with pkgs; [ chatgpt-cli ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # OpenAI released an official ChatGPT desktop application for Linux on
    # 2026-08-11. However, NixOS is not officially supported by OpenAI
    # (as of writing this (2026-10-01)).
    #
    # The community has created several unofficial Nix flake that package the
    # official Linux `.deb` binary for NixOS that download the upstream app
    # directly from OpenAI's servers and adjust runtime paths for Nix
    # compatibility.
    #
    # Additionally, the Linux version currently lacks some features available on
    # other platforms, such as Computer Use, and native Wayland support remains
    # experimental.
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.gui.enable && cfg.gui.chatgptDesktop.enable) {
      home.packages = with pkgs; [ chatgpt ];
    })
  ];
}
