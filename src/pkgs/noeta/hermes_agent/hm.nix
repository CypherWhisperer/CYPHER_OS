# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hermes_agent/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Requires the upstream module in the Home Manager imports:
#   inputs.hermes-agent.homeManagerModules.default
#
# The gateway runs as a `systemd --user` unit. Home Manager cannot enable
# linger, so system.nix handles that on NixOS; on other systems a one-time
# `loginctl enable-linger <user>` is needed.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.hermes.enable) {
      programs.hermes-agent.enable = true;

      services.hermes-agent = {
        enable = true;
        gateway.enable = cfg.hermes.gateway.enable;

        # ────────────────────────────────────────────────────────────────────
        # settings.model.default is deliberately NOT declared here.
        #
        # Any key declared through Nix becomes Nix-owned: the activation merge
        # re-applies it on every rebuild, and the Hermes CLI refuses to change
        # it at runtime (the .managed marker). Leaving the key out keeps model
        # switching imperative and free, while every other key stays editable
        # at runtime as well.
        #
        # Possible future use: declare it (e.g. through a cypherOsConstants
        # entry) wherever a Nix-enforced baseline is wanted that must resist
        # drift: a CI host, a shared account, or any machine where a fixed
        # model is non-negotiable.
        # ────────────────────────────────────────────────────────────────────

        # Provider credentials are not configured here yet. Upstream expects
        # them through `environmentFiles` (e.g. a sops-managed secret).
      };
    })

    (lib.mkIf (cfg.hermes.enable && cfg.hermes.gui.enable) {
      programs.hermes-agent.desktop.enable = true;
    })
  ];
}
