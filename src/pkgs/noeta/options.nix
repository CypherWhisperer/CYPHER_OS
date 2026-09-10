# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/neota/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.noeta = {
    enable = lib.mkEnableOption "CypherOS AI and Agentic workflow(s) tooling and configurations.";

    openCode.enable = lib.mkEnableOption "OpenCode harness.";
    claudeCode.enable = lib.mkEnableOption "Claude Code harness.";
    codex.enable = lib.mkEnableOption "Codex Harness.";
    hermes.enable = lib.mkEnableOption "Hermes Agent; The agent that grows with you.";

    gui = {
      enable = lib.mkEnableOption "CypherOS noets GUI (Graphical User Interface) Packages.";

      t3Code.enable = lib.mkEnableOption "T3 Code from t3.gg (Theo)";
    };
  };
}
