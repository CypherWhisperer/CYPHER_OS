# ──────────────────────────────────────────────────────────────────────────────
# src/shell/nushell.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [
    ./options.nix
  ];
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.nushell.enable) {
      home.packages = with pkgs; [
        nushell
      ];
    })

    {
      assertions = [
        {
          assertion = cfg.nushell.enable -> cfg.enable;
          message = ''
            cypher-os.shell.nushell.enable requires cypher-os.shell.enable.
          '';
        }
      ];
    }
  ];
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: NUSHELL CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────
# programs.nushell is a valid configuration module in NixOS and Home Manager.
# Allows users to enable Nushell, specify the package version, and configure
# settings such as aliases, environment variables, and completion integrations
# (e.g., with Carapace or Starship).
# ──────────────────────────────────────────────────────────────────────────────
# Key options include:
# ──────────────────────────────────────────────────────────────────────────────
# enable:                   Activates the Nushell module.
# configFile / extraConfig: Defines the main configuration (config.nu).
# envFile / extraEnv:       Defines environment variable initialization (env.nu).
# shellAliases:             Maps standard shell aliases to Nushell syntax.
# plugins:                  Registers external Nushell plugins.
# ──────────────────────────────────────────────────────────────────────────────
# For a robust setup, it is often recommended to use Nushell as the default shell
# for applications while keeping a POSIX shell (like Bash or Zsh) as the system
# login shell to avoid issues with environment variable inheritance during boot.
# ──────────────────────────────────────────────────────────────────────────────
