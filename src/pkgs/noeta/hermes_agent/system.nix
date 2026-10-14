# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hermes_agent/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# NixOS (system) context. Holds only what Home Manager cannot do: enabling
# systemd linger for the account. Without linger, systemd stops the user
# manager at logout and the Hermes gateway (a user unit) stops with it; cron
# dispatch also fails closed without a persistent user bus.
#
# Gated on the gateway, since the CLI alone needs no persistent user manager.
# Disabling the gateway leaves nothing from this file in the system config.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta.hermes;
  username = cypherOsConstants.username;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = lib.mkIf (cfg.enable && cfg.gateway.enable) {
    users.users.${username}.linger = true;
  };
}
