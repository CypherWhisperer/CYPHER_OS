# ──────────────────────────────────────────────────────────────────────────────
# src/system/networking/default.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
let
  values = import ../../config/constants/values.nix;
  activeHostName = values.activeHostName;
  username = values.username;
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

    # ──────────────────────────────────────────────────────────────────────────
    # Makes NixOS's default firewall behavior explicit rather than implicit, and
    # gives a single toggle for connection-refusal logging during
    # troubleshooting. Intentionally minimal — a full network-security pass
    # (zones, per-service rules, egress policy) is its own future session.
    # ──────────────────────────────────────────────────────────────────────────
    firewall = {
      enable = true; # matches current (implicit) default — now declared

      # ────────────────────────────────────────────────────────────────────────
      # temporary: surfaces drops in `journalctl -k`during troubleshooting.
      # NOTE: TO BE ROPPED.
      # ────────────────────────────────────────────────────────────────────────
      logRefusedConnections = true;
    };
  };
  users.users.${username}.extraGroups = [
    "networkmanager" # manage network connections without sudo
  ];

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
