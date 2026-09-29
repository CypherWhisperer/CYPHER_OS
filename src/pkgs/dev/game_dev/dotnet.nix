# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/game_dev/dotnet.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# .NET SDK and the C# tooling shared by both IDEs (VSCode and Neovim):
#   - roslyn-ls : the language server behind C# Dev Kit, also used by roslyn.nvim
#   - csharpier : the common formatter
# Both IDEs resolve the same store paths, so behaviour stays consistent.
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
    (lib.mkIf (cfg.enable && cfg.dotnet.enable) {
      home.packages = [
        cfg.dotnet.sdk
        pkgs.roslyn-ls
        pkgs.csharpier
      ];

      home.sessionVariables = {
        # ──────────────────────────────────────────────────────────────────────
        # Opt out of dotnet CLI telemetry.
        # ──────────────────────────────────────────────────────────────────────
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";

        # ──────────────────────────────────────────────────────────────────────
        # C# Dev Kit has failed to locate the runtime on NixOS when DOTNET_ROOT
        # is unset (NixOS/nixpkgs#389351). The NixOS wiki documents
        # "${sdk}/share/dotnet" for a single SDK package.
        # ──────────────────────────────────────────────────────────────────────
        # NOTE: not yet fully verified: check with `dotnet --info` after the
        # switch. A combinePackages override may need a different path.
        # ──────────────────────────────────────────────────────────────────────
        DOTNET_ROOT = "${cfg.dotnet.sdk}/share/dotnet";
      };
    })
  ];
}
