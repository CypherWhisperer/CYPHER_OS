# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [
    ./options.nix
    ./claude_code.nix
    ./claude_desktop.nix
    ./codex.nix
    ./open_code.nix
    ./t3_code.nix
    ./dsh.nix
    ./chatgpt.nix
    ./gemini_cli.nix
    ./ollama.nix
    ./qwen_code.nix
    ./hermes_agent/hm.nix
  ];

  config = lib.mkMerge [
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.noeta.enable = lib.mkDefault true;

      cypher-os.pkgs.noeta.openCode.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.claudeCode.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.codex.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.dsh.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.chatgptCli.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.geminiCli.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.ollama.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.noeta.qwenCode.enable = lib.mkDefault cfg.enable;
      
      cypher-os.pkgs.noeta.gui.enable = lib.mkDefault (cfg.enable && cypherOsProfile == "desktop");
      cypher-os.pkgs.noeta.gui.t3Code.enable = lib.mkDefault false; # overriden
      cypher-os.pkgs.noeta.gui.claudeDesktop.enable = lib.mkDefault cfg.gui.enable;
      cypher-os.pkgs.noeta.gui.chatgptDesktop.enable = lib.mkDefault false; # overriden
      cypher-os.pkgs.noeta.gui.ollamaGui.enable = lib.mkDefault cfg.gui.enable;
      
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.openCode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.openCode.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.claudeCode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.claudeCode.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.codex.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.codex.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.dsh.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.dsh.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.chatgptCli.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.chatgptCli.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.geminiCli.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.geminiCli.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.qwenCode.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.qwenCode.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.ollama.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.ollama.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        
        {
          assertion = cfg.gui.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.enable requires
            cypher-os.pkgs.noeta.enable.
          '';
        }
        {
          assertion = cfg.gui.enable -> (cypherOsProfile == "desktop");
          message = ''
            cypher-os.pkgs.noeta.gui.enable requires
            cypher-os.profile.active == "desktop".
          '';
        }
        {
          assertion = cfg.gui.t3Code.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.t3Code.enable requires
            cypher-os.pkgs.noeta.gui.enable.
          '';
        }
        {
          assertion = cfg.gui.claudeDesktop.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.claudeDesktop.enable requires
            cypher-os.pkgs.noeta.gui.enable.
          '';
        }
        {
          assertion = cfg.gui.chatgptDesktop.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.chatgptDesktop.enable requires
            cypher-os.pkgs.noeta.gui.enable.
          '';
        } 
        {
          assertion = cfg.gui.ollamaGui.enable -> cfg.gui.enable;
          message = ''
            cypher-os.pkgs.noeta.gui.ollamaGui.enable requires
            cypher-os.pkgs.noeta.gui.enable.
          '';
        }
      ];
    }
  ];
}
