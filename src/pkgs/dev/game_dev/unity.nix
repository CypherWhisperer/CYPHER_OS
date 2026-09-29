# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/game_dev/unity.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Unity Hub.
#
# Unity supports only FHS Linux distributions, so nixpkgs wraps the Hub in an
# FHS environment. The editors the Hub downloads land in ~/Unity/Hub/Editor and
# are NOT managed by Nix; the editor version is pinned per project through
# ProjectSettings/ProjectVersion.txt.
#
# Editor pin: Unity 6000.3 LTS (supported until December 2027). Unity 6000.6+
# is avoided: the editor crashes on project open under the nixpkgs FHS wrapper
# (NixOS/nixpkgs#561247, shader compiler cannot find libtinfo.so.6).
#
# `unityhub` is unfree: it needs an allowUnfree entry wherever the package set
# used by Home Manager is configured.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.gameDev.gui;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [

    # ──────────────────────────────────────────────────────────────────────────
    # DESKTOP ONLY, GUI PACKAGE(S).
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cfg.enable && cfg.unity.enable) {
      home.packages = [ pkgs.unityhub ];
    })
  ];
}
