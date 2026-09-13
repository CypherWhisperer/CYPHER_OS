# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/rustdesk_system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.rustdesk.enable && cfg.rustdesk.server.enable) {
    services.rustdesk-server = {
      enable = true;
      openFirewall = cfg.rustdesk.server.openFirewall;

      signal = {
        enable = true;
        relayHosts = cfg.rustdesk.server.relayHosts;
        extraArgs = cfg.rustdesk.server.signalExtraArgs;
      };

      relay = {
        enable = true;
        extraArgs = cfg.rustdesk.server.relayExtraArgs;
      };
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Key pair (id_ed25519 / id_ed25519.pub) is generated on first hbbs
    # start, at /var/lib/private/rustdesk/. The .pub contents are what every
    # client needs entered as the server's public key to connect.
    # ──────────────────────────────────────────────────────────────────────────
  };
}
