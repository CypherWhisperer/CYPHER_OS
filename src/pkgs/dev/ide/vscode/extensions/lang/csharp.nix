# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/vscode/extensions/lang/csharp.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  gameDev = config.cypher-os.pkgs.dev.gameDev;
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.csharp.enable) {
    programs.vscode.profiles.default.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────
        # NOTE: C# Dev Kit (csdevkit) and the Unity extension are Microsoft
        # proprietary. Their licence terms make them free for individuals,
        # academia and open-source work, but they are tied to Microsoft's VS
        # Code build and are not available for VSCodium (the C# debugger is
        # restrictively licensed to the official build).
        # ──────────────────────────────────────────────────────────────────────
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit
        ms-dotnettools.vscode-dotnet-runtime
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
        # CSharpier: the formatter shared with Neovim.
        # ──────────────────────────────────────────────────────────────────────
        vscMkt.csharpier.csharpier-vscode
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # Use the Roslyn language server (the default), not legacy OmniSharp.
      # ────────────────────────────────────────────────────────────────────────
      "dotnet.server.useOmnisharp" = false;

      "[csharp]" = {
        "editor.defaultFormatter" = "csharpier.csharpier-vscode";
        "editor.formatOnSave" = true;
      };
    }
    // lib.optionalAttrs gameDev.dotnet.enable {
      # ────────────────────────────────────────────────────────────────────────
      # Point the .NET Install Tool at the Nix-provided SDK instead of letting
      # it download its own runtime.
      #
      # NOTE: setting name recalled from .NET Install Tool docs and not yet
      # verified; check on first activation.
      # ────────────────────────────────────────────────────────────────────────
      "dotnetAcquisitionExtension.existingDotnetPath" = [
        {
          extensionId = "ms-dotnettools.csharp";
          path = "${gameDev.dotnet.sdk}/share/dotnet/dotnet";
        }
      ];
    };
  };
}
