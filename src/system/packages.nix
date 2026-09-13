# ──────────────────────────────────────────────────────────────────────────────
# src/system/packages.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  pkgs,
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # SYSTEM PACKAGES
  # ────────────────────────────────────────────────────────────────────────────
  # Packages listed here are installed system-wide (available to all users,
  # in the system PATH).
  # Keep this minimal — user-space apps belong in Home Manager, not here.
  #
  # What belongs here: tools needed before Home Manager runs, or tools that
  # genuinely require system-level installation.
  # ────────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl # needed for initial Nix/HM bootstrap commands
    vim # emergency editor before HM applies neovim
    os-prober # for detecting other OSs in a multi-boot setup
    glib # needed for gdmBackground activation script
    hydra-check # to check the health of flake inputs and their updates

    # ──────────────────────────────────────────────────────────────────────────
    # the home-manager CLI must be on the system PATH
    # ──────────────────────────────────────────────────────────────────────────
    home-manager
  ];
}
