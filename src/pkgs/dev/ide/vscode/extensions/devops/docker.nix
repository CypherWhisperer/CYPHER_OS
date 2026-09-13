# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/devops/docker.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.devops.docker.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-containers
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────

        # ── DevOps: Docker Compose ────────────────────────────────────────────
        # ──────────────────────────────────────────────────────────────────────
        # p1c2u's Docker Compose extension.
        # ──────────────────────────────────────────────────────────────────────
        vscMkt.p1c2u.docker-compose

        # ── DevOps: Docker Extension Pack (Jun Han) ───────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # The pack itself; ms-azuretools.vscode-docker is already in
        # Tier 1 above.
        # ──────────────────────────────────────────────────────────────────────
        vscMkt.formulahendry.docker-extension-pack
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      "[dockerfile]" = {
        "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
      };

      "docker.showStartPage" = false;
    };
  };
}
