# ──────────────────────────────────────────────────────────────────────────────
# src/shell/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
let
  cfg = cypher-os.shell;
in
{
  imports = [
    ./options.nix
    ./defaults.nix
    ./zsh.nix
    ./nushell.nix
    ./fish.nix
  ];
}
