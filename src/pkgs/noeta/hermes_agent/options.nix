# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hermes_agent/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.noeta.hermes = {
    enable = lib.mkEnableOption "Hermes Agent; the agent that grows with you.";

    gateway.enable = lib.mkEnableOption "the Hermes messaging/cron gateway as a long-running user service.";

    gui = {
      enable = lib.mkEnableOption "Hermes Desktop (Electron) application.";
    };
  };
}
