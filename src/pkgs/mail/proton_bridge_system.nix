# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/mail/proton_bridge_system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.mail;
  inherit (lib) mkIf;
in
{
  imports = [ ./options.nix ];

  config = mkIf (cfg.enable && cfg.protonBridge.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # Bridge requires the freedesktop.org Secret Service API to persist its
    # Proton session token across reboots. GNOME Keyring is the supported
    # Secret Service backend on NixOS/GNOME.
    # ──────────────────────────────────────────────────────────────────────────
    services.gnome.gnome-keyring.enable = true;

    # ──────────────────────────────────────────────────────────────────────────
    # Ensure PAM unlocks the login keyring on session start so Bridge can
    # retrieve its stored credentials without user interaction on subsequent
    # boots (after the one-time interactive login ceremony).
    # ──────────────────────────────────────────────────────────────────────────
    security.pam.services.login.enableGnomeKeyring = true;
  };
}
