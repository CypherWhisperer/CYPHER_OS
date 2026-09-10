# ──────────────────────────────────────────────────────────────────────────────
# src/dev/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  options.cypher-os.pkgs.dev = {
    enable = mkEnableOption "CypherOS development environment";

    git.enable = mkEnableOption "Git Version Control System";
    ssh.enable = mkEnableOption "SSH client configuration";
    devenv.enable = mkEnableOption "devenv configuration for CypherOS";
    direnv.enable = mkEnableOption "direnv configuration for CypherOS";

    # ide -> ./ide/options.nix
    # languages -> ./languages/options.nix
    # arduino -> ./arduino/options.nix
  };
}
