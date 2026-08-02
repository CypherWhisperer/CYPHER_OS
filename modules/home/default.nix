# modules/home/default.nix
#
# Home Manager evaluation root for cypher_whisperer.
#
# RESPONSIBILITIES:
#   1. Unconditionally import every module that declares cypher-os.* options —
#      options must exist in the merged set before any mkIf can reference them.
#   2. Own home.stateVersion — set once, never change.
#   3. Own nothing else. DE config, app config, and profile defaults all live
#      in their respective modules and are activated via cypher-os options.
#
# WHAT DOES NOT LIVE HERE:
#   - DE-specific config              → modules/de/<de>.nix
#   - App package lists               → modules/apps/<group>/default.nix
#   - Profile cascade logic           → modules/profile/default.nix
#   - System-level config             → hosts/nixos/configuration.nix

{ ... }:

{
  # Every module that declares a cypher-os.* option must appear here.
  # This is unconditional — imports are not guarded by mkIf.
  # The modules themselves use mkIf internally to decide what to install.
  imports = [
    ../../modules
    # Currently hitting an error:
    # (error: error parsing derivation '/nix/store/nzhz804z407sw3zi40ls5h71jdsgcpgm-home-manager-auto-expire.service.drv': file is empty (possible filesystem corruption))
    # Commenting this to check if the problem in code-related or workflow
    # ./gc-hm.nix
  ];
  # ─────────────────────────────────────────────────────────────────────────────
  # HOME MANAGER STATE VERSION
  # ─────────────────────────────────────────────────────────────────────────────
  # Set once, never change. This tells HM which release its config schema was
  # written against. It gates HM migration logic, not which packages you receive.
  home.stateVersion = "24.11";
}
