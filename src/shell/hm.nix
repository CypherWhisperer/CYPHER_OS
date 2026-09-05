# ──────────────────────────────────────────────────────────────────────────────
# src/shell/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:

{
  imports = [
    ./options.nix
    ./zsh.nix
    ./nushell.nix
    ./fish.nix
  ];

  config = lib.mkMerge [
    # (lib.mkIf && cfg.enable {}) # Currently no logic to gate:

    {
      cypher-os.shell.zsh.enable = lib.mkDefault true;
      cypher-os.shell.fish.enable = lib.mkDefault true;
      cypher-os.shell.nushell.enable = lib.mkDefault true;

    }

    {
      cypher-os.shell.enable = lib.mkDefault true;
    }
  ];
}
