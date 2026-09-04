# ──────────────────────────────────────────────────────────────────────────────
# src/shell/fish.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.cypher-os.shell;
in
{
  imports = [
    ./options.nix
  ];
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.fish.enable) {
      home.packages = with pkgs; [
        fish
      ];
    })

    {
      assertions = [
        {
          assertion = cfg.fish.enable -> cfg.enable;
          message = ''
            cypher-os.shell.fish.enable requires cypher-os.shell.enable.
          '';
        }
      ];
    }
  ];
}
