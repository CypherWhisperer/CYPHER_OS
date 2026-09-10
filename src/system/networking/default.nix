# ──────────────────────────────────────────────────────────────────────────────
# src/system/networking/default.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
let
  values = import ../../config/constants/values.nix;
  activeHostName = values.activeHostName;
in
{
  # ────────────────────────────────────────────────────────────────────────────
  # NETWORKING
  # ────────────────────────────────────────────────────────────────────────────
  # NetworkManager handles WiFi and wired connections. The GNOME network
  # indicator and Settings panel talk to it via D-Bus.
  # ────────────────────────────────────────────────────────────────────────────
  networking = {
    hostName = activeHostName;
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
  # ────────────────────────────────────────────────────────────────────────────
  # CONSIDER: handling DNS resolution, instead of the router (resolved approach)
  # ────────────────────────────────────────────────────────────────────────────
  # services.resolved.enable = true;
  # services.resolved.fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  #
  # networking.networkmanager.enable = true;
  # networking.networkmanager.dns = "systemd-resolved";
  # ────────────────────────────────────────────────────────────────────────────
}
