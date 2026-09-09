# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/vscode/default.nix
# ──────────────────────────────────────────────────────────────────────────────
# Home Manager module for VSCode and its forks (Cursor, Antigravity).
#
# ──────────────────────────────────────────────────────────────────────────────
# ARCHITECTURE:
# ──────────────────────────────────────────────────────────────────────────────
# VSCode forks share one settings.json — deployed via xdg.configFile to
# each editor's config path. Extensions are managed per-editor since each
# fork has its own extension host and marketplace integration.
#
# programs.vscode handles the VSCode binary and its extensions declaratively.
# Cursor and Antigravity share the settings deployed via xdg.configFile.
#
#
# ──────────────────────────────────────────────────────────────────────────────
# MAPLE MONO FONT NOTE:
# ──────────────────────────────────────────────────────────────────────────────
# settings.json specifies Maple Mono as the editor font. Not in nixpkgs.
# To install:
#   1. Download from https://github.com/subframe7536/maple-font/releases
#   2. Place TTF files in configs/fonts/maple-mono/
#   3. Add a home.file entry deploying them to ~/.local/share/fonts/
#   4. Run `fc-cache -f` once after first switch
# Until then the config falls back to JetBrains Mono (already installed).
#
# ──────────────────────────────────────────────────────────────────────────────
# SHARED SETTINGS STRATEGY:
# ──────────────────────────────────────────────────────────────────────────────
# One settings.json is deployed to {VSCode,Cursor,Antigravity} ->:
# (./core_config.nix). If editor-specific overrides are needed, add separate
# xdg.configFile entry  that writes only the differing keys — the last writer
# wins for each key in  VSCode's settings merge.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui;
in
{
  imports = [
    ./options.nix
    ./extensions
    ./core_config.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.vscode.enable) {
      programs.vscode = {
        enable = true;

        # ──────────────────────────────────────────────────────────────────────
        # mutableExtensionsDir = false: prevents VSCode from writing to the
        # extensions directory at runtime. All extensions come from Nix.
        # Set to true if you want to install extensions manually alongside
        # the Nix-managed ones (useful while evaluating new extensions).
        #
        # Required by the workaround for home-manager regression b593765 (Feb 1,
        # 2026, "vscode: fix extension path for antigravity"). That commit
        # changed how .extensions-immutable.json is generated, which caused VS
        # Code to mark all Nix-managed extensions as obsolete on load —
        #extensions were correctly symlinked but invisible to the editor.
        #
        # The workaround (HM issue #8793) requires extensions at the top-level
        # programs.vscode.extensions key rather than profiles.default.extensions.
        # That key only takes effect when mutableExtensionsDir = false.
        #
        # Revert to true (and move extensions back to profiles.default.extensions)
        # once upstream resolves:
        # https://github.com/nix-community/home-manager/issues/8793
        # ──────────────────────────────────────────────────────────────────────
        mutableExtensionsDir = false;
      };
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.dev.ide.gui.vscode.enable = lib.mkDefault cfg.enable;

      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.d2.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.go.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.lua.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.nix.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.php.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.sql.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.dart.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.rust.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.cCpp.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.jsTs.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.asm.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.kotlin.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.python.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.arduino.enable = lib.mkDefault cfg.vscode.enable;

      cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.docker.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.k8s.enable = lib.mkDefault cfg.vscode.enable;
      cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.core.enable = lib.mkDefault cfg.vscode.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.vscode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.enable requires cypher-os.pkgs.dev.ide.gui.enable.
          '';
        }

        {
          assertion = cfg.vscode.extensions.lang.d2.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.d2.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.go.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.go.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.lua.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.lua.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.nix.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.nix.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.php.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.php.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.sql.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.sql.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.dart.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.dart.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.rust.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.rust.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.cCpp.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.cCpp.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.jsTs.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.jsTs.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.asm.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.asm.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.kotlin.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.kotlin.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.python.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.python.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.lang.arduino.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.lang.arduino.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }

        {
          assertion = cfg.vscode.extensions.devops.core.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.core.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.devops.docker.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.docker.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
        {
          assertion = cfg.vscode.extensions.devops.k8s.enable -> cfg.vscode.enable;
          message = ''
            cypher-os.pkgs.dev.ide.gui.vscode.extensions.devops.k8s.enable requires cypher-os.pkgs.dev.ide.gui.vscode.enable.
          '';
        }
      ];
    }
  ];
}
