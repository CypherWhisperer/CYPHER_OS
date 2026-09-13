# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/rustdesk_hm.nix
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

  config = lib.mkIf (cfg.enable && cfg.rustdesk.enable) {
    home.packages = [ pkgs.rustdesk-flutter ];
    # ──────────────────────────────────────────────────────────────────────────
    # This client works out of the box against RustDesk's public hbbs/hbbr —
    # no dependency on rustdesk-system.nix being enabled. If the server
    # module IS enabled on a given host, point this client's ID/Relay Server
    # fields (Settings > Network, in-app) at that host manually — there's no
    # automatic wiring between the HM client config and the NixOS server
    # config, since that's the client's own runtime state, not a Nix option.
    # ──────────────────────────────────────────────────────────────────────────
  };
}
