{
  config,
  lib,
  ...
}:

let
  cfg = config.cypher-os.apps.productivity.rustdesk;
in

{
  imports = [ ./options.nix ];

  config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable && cfg.server.enable) {

    services.rustdesk-server = {
      enable = true;
      openFirewall = cfg.server.openFirewall;

      signal = {
        enable = true;
        relayHosts = cfg.server.relayHosts;
        extraArgs = cfg.server.signalExtraArgs;
      };

      relay = {
        enable = true;
        extraArgs = cfg.server.relayExtraArgs;
      };
    };

    # Key pair (id_ed25519 / id_ed25519.pub) is generated on first hbbs
    # start, at /var/lib/private/rustdesk/. The .pub contents are what every
    # client needs entered as the server's public key to connect.
  };
}
