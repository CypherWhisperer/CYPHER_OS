# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Home manager module for Development environment: runtime tooling, compilers,
# language servers, and ecosystem-specific engine wiring.
#
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev;
in
{
  imports = [
    ./options.nix
    ./git.nix
    ./ssh.nix
    ./direnv.nix
    ./devenv.nix
    ./ide/hm.nix
    ./languages/hm.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      home.packages = with pkgs; [

        # ── General tooling ───────────────────────────────────────────────────
        jq # JSON processor — useful for inspecting API responses, CI
        httpie # Human-friendly HTTP client; complements curl for API dev

        # ──────────────────────────────────────────────────────────────────────
        # Cryptographic library that implements the SSL and TLS protocols.
        # ──────────────────────────────────────────────────────────────────────
        openssl

        # ──────────────────────────────────────────────────────────────────────
        # BUILD TOOLCHAIN FUNDAMENTALS.
        # ──────────────────────────────────────────────────────────────────────
        # gnumake: the GNU make build system. Required by many native build
        # processes (C extensions in Python packages, some Rust crates, Node.js
        # native modules).
        # ──────────────────────────────────────────────────────────────────────
        gnumake
      ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.dev.enable = lib.mkDefault true;

      cypher-os.pkgs.dev.git.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.ssh.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.direnv.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.dev.devenv.enable = lib.mkDefault cfg.enable;
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.git.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.git.enable requires cypher-os.pkgs.dev.enable.
          '';
        }
        {
          assertion = cfg.ssh.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.ssh.enable requires cypher-os.pkgs.dev.enable.
          '';
        }
        {
          assertion = cfg.direnv.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.direnv.enable requires cypher-os.pkgs.dev.enable.
          '';
        }
        {
          assertion = cfg.devenv.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.dev.devenv.enable requires cypher-os.pkgs.dev.enable.
          '';
        }
      ];
    }
  ];
}
