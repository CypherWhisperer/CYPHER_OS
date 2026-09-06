# ──────────────────────────────────────────────────────────────────────────────
# src/shell/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.shell.enable = lib.mkDefault true;
    cypher-os.shell.zsh.enable = lib.mkDefault cfg.enable;
    cypher-os.shell.fish.enable = lib.mkDefault cfg.enable;
    cypher-os.shell.nushell.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.zsh.enable -> cfg.enable;
        message = ''
          cypher-os.shell.zsh.enable requires cypher-os.shell.enable.
        '';
      }

      {
        assertion = cfg.fish.enable -> cfg.enable;
        message = ''
          cypher-os.shell.fish.enable requires cypher-os.shell.enable.
        '';
      }

      {
        assertion = cfg.nushell.enable -> cfg.enable;
        message = ''
          cypher-os.shell.nushell.enable requires cypher-os.shell.enable.
        '';
      }
    ];
  };
}
