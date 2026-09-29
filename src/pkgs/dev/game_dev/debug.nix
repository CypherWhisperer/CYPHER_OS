# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/game_dev/debug.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Debugging support. Two separate runtimes are involved, so two separate tools:
#   - netcoredbg : plain .NET (CoreCLR) C# programs.
#   - mono       : Unity runs on Mono and is debugged over the Mono soft
#                  debugger. The community adapter (unity-dap) needs a Mono
#                  install to run. unity-dap itself is not packaged here.
#
# VSCode uses the debugger bundled with the Unity extension, so these are
# consumed by Neovim (nvim-dap).
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.gameDev;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [

    (lib.mkIf (cfg.enable && cfg.debug.netcoredbg.enable) {
      home.packages = [ pkgs.netcoredbg ];
    })

    (lib.mkIf (cfg.enable && cfg.debug.mono.enable) {
      home.packages = [ pkgs.mono ];
    })
  ];
}
