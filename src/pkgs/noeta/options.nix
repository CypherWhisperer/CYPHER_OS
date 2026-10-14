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
    geminiCli.enable = lib.mkEnableOption "Gemini CLI harness.";
    chatgptCli.enable = lib.mkEnableOption "ChatGPT CLI.";
    qwenCode.enable = lib.mkEnableOption "Qwen Code Harness.";
    dsh.enable = lib.mkEnableOption "DeepSeek Harness.";
    ollama.enable = lib.mkEnableOption "Ollama LLM package manager and runtime.";

    # hermes -> ./hermes_agent/options.nix

    gui = {
      enable = lib.mkEnableOption "CypherOS noets GUI (Graphical User Interface) Packages.";

      t3Code.enable = lib.mkEnableOption "T3 Code from t3.gg (Theo)";
      chatgptDesktop.enable = lib.mkEnableOption "ChatGPT Desktop Application.";
      claudeDesktop.enable = lib.mkEnableOption "Claude Desktop";
      ollamaGui.enable = lib.mkEnableOption "Ollama GUI (Graphical User Interface) Convenience(s).";

      # ────────────────────────────────────────────────────────────────────────
      # Dropped for the moment:
      # check documentation (ADR_029, docs/source_docs/src/pkgs/noeta/dsh.nix)
      # ────────────────────────────────────────────────────────────────────────
      # dshDesktop.enable = lib.mkEnableOption "Deepseek Herness Desktop Application.";
    };
  };
}
