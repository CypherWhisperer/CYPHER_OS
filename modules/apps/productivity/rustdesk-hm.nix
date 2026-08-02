{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cypher-os.apps.productivity.rustdesk;
in

{
  config = lib.mkIf (config.cypher-os.apps.productivity.enable && cfg.enable) {

    home.packages = [ pkgs.rustdesk-flutter ];

    # No allowUnfree concern; RustDesk client + server are both OSI licensed.

    # This client works out of the box against RustDesk's public hbbs/hbbr —
    # no dependency on rustdesk-system.nix being enabled. If the server
    # module IS enabled on a given host, point this client's ID/Relay Server
    # fields (Settings > Network, in-app) at that host manually — there's no
    # automatic wiring between the HM client config and the NixOS server
    # config, since that's the client's own runtime state, not a Nix option.
  };
}
