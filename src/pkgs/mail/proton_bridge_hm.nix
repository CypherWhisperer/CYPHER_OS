# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/mail/proton_bridge_hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
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

    home.packages = [ pkgs.protonmail-bridge ];

    # ──────────────────────────────────────────────────────────────────────────
    # Bridge runs as a persistent systemd user service.
    # It must be running before Thunderbird can access any Proton Mail account.
    # The service starts headlessly (no system tray window) via --no-window.
    # ──────────────────────────────────────────────────────────────────────────
    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "Proton Mail Bridge local IMAP/SMTP proxy";
        # ──────────────────────────────────────────────────────────────────────
        # Defer start until the network is up and the GNOME Keyring Secret
        # Service socket is available — Bridge retrieves its stored session
        # token from the keyring at startup.
        # ──────────────────────────────────────────────────────────────────────
        After = [
          "network-online.target"
          "gnome-keyring-daemon.service"
        ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --no-window";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
