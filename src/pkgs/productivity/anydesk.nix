# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/anydesk.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.anydesk.enable) {
    home.packages = with pkgs; [ anydesk ];

    # ──────────────────────────────────────────────────────────────────────────
    # Unattended access (not enabled here)
    # ──────────────────────────────────────────────────────────────────────────
    # Current setup is interactive/normal mode only: launching the app
    # generates a fresh session ID + one-time password each time, and every
    # incoming connection requires an explicit Accept click on this machine.
    #
    # If unattended access is wanted later, it's a two-part change:
    #   1. A permanent password set in AnyDesk's own security settings
    #      (not a Nix option — lives in AnyDesk's runtime config, so this
    #      would need `home.activation` or manual first-run setup).
    #
    #   2. The background service running independent of a login session —
    #      the anydesk package ships a systemd unit at
    #      `${pkgs.anydesk}/lib/systemd/system/anydesk.service`, but nixpkgs
    #      does NOT wire it into systemd.services automatically. Enabling it
    #      would mean adding, at the system (not HM) level:
    #        systemd.packages = [ pkgs.anydesk ];
    #        systemd.services.anydesk.wantedBy = [ "multi-user.target" ];
    #
    # That combination turns this from "reachable only while I have the app
    # open and click Accept" into "reachable 24/7 by anyone with the fixed
    # password" — a pro but, given it's a standing root-level daemon, it might
    # expose an attack surface.
    #
    # Consult session file (ANYDESK_&_RUSTDESK) for more
    # ──────────────────────────────────────────────────────────────────────────
  };
}
