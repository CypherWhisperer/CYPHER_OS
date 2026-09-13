# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/devops/core.nix
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

  config = lib.mkIf (cfg.enable && cfg.extensions.devops.core.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        # ── Web: Prisma ───────────────────────────────────────────────────────
        # Syntax highlighting, formatting, auto-completion, and
        # jump-to-definition for .prisma schema files. In nixpkgs — no
        # marketplace fetch needed.
        # ──────────────────────────────────────────────────────────────────────
        prisma.prisma

        # ── DevOps: CI/CD ─────────────────────────────────────────────────────
        github.vscode-github-actions

        # ── Containers  ───────────────────────────────────────────────────────
        ms-azuretools.vscode-containers
        ms-vscode-remote.remote-containers
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────

        # ── Caddy ─────────────────────────────────────────────────────────────
        vscMkt.matthewpi.caddyfile-support

        # ──────────────────────────────────────────────────────────────────────
        # DotEnv
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # .env syntax highlighting (mikestead)
        # ──────────────────────────────────────────────────────────────────────
        # Syntax highlighting and basic validation for .env files.
        # Applies to: Laravel's .env, Symfony's .env.local, and any
        # key=value environment file in any project.
        # ──────────────────────────────────────────────────────────────────────
        vscMkt.mikestead.dotenv
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
    };
  };
}
