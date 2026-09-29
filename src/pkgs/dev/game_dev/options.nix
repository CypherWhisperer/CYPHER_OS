# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/game_dev/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  ...
}:
{
  options.cypher-os.pkgs.dev.gameDev = {
    enable = lib.mkEnableOption "game development tooling (Unity and C#/.NET)";

    gui = {
      enable = lib.mkEnableOption "GUI game development packages";

      unity.enable = lib.mkEnableOption ''
        Unity Hub. The Hub is FHS-wrapped by nixpkgs; the editors it downloads
        are NOT managed by Nix
      '';
    };

    dotnet = {
      enable = lib.mkEnableOption ''
        the .NET SDK and the C# tooling shared by VSCode and Neovim
        (roslyn-ls, csharpier)
      '';

      sdk = lib.mkOption {
        type = lib.types.package;
        default = pkgs.dotnetCorePackages.sdk_9_0;
        defaultText = lib.literalExpression "pkgs.dotnetCorePackages.sdk_9_0";
        description = ''
          The .NET SDK used by the language server and `dotnet` CLI.
          This default is a placeholder choice: the SDK version roslyn-ls
          requires has not been verified yet. Override with a
          `dotnetCorePackages.combinePackages [ ... ]` result if several SDKs
          are needed (DOTNET_ROOT handling in dotnet.nix then needs a re-check).
        '';
      };
    };

    debug = {
      netcoredbg.enable = lib.mkEnableOption ''
        netcoredbg, a debugger for plain .NET C# (not for Unity, which runs on
        Mono)
      '';

      mono.enable = lib.mkEnableOption ''
        Mono, needed to run the Mono-based Unity debug adapter (unity-dap)
        used from Neovim
      '';
    };
  };
}
