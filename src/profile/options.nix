# ──────────────────────────────────────────────────────────────────────────────
# src/profile/options.nix
# ──────────────────────────────────────────────────────────────────────────────
# Declares the two cross-context SSOT signals introduced in ADR-023/ADR-024.
# Imported by both the NixOS graph (via src/system/default.nix's
# src/profile/system.nix) and the Home Manager graph (via
# src/home/default.nix's src/profile/hm.nix), per the ADR-005 invariant
# that options are declared once but visible in both contexts.
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os = {
    profile.active = lib.mkOption {
      type = lib.types.enum [
        "desktop"
        "server"
      ];
      description = ''
        The single active system profile. Replaces the old dual
        `profile.{desktop,server}.enable` booleans (ADR-001) — an enum
        makes the both-true / both-false invalid states unrepresentable
        rather than merely discouraged by convention. See ADR-023.
      '';
    };

    lens.current = lib.mkOption {
      type = lib.types.enum [
        "nixos"
        "arch"
        "debian"
        "fedora"
        "opensuse"
      ];
      description = ''
        Which host lens (OS distribution) is currently active. Lets
        lens-dependent categories (e.g. fonts) branch without manually
        duplicating package lists between hm.nix and system.nix. See
        ADR-023/ADR-024.
      '';
    };
  };
}
