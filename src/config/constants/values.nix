# ──────────────────────────────────────────────────────────────────────────────
# src/config/constants/values.nix
# ──────────────────────────────────────────────────────────────────────────────
# Plain data, not a module — importable at flake level
# (before any evalModules call exists) and from within any module (system.nix,
# flake/home-configurations.nix, and anywhere else a raw literal is needed).
#
# This is the actual single source; cypher-os.constants.* and
# home.homeDirectory / users.users.<name>.home all derive from this,
# never from each other.
# ──────────────────────────────────────────────────────────────────────────────

{
  username = "cypher_whisperer";
  homeDirectory = "/home/cypher-whisperer";
  primaryDisk = "/dev/sda";

  # Needed to ensure flake's HM configuration is aligned to active profile
  activeProfile = "desktop";
}
