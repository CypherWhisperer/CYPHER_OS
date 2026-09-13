# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  imports = [
    ./options.nix
    ./defaults.nix

    ./affine_hm.nix
    ./anydesk.nix
    ./claude.nix
    ./drawio.nix
    ./libreoffice.nix
    ./logseq.nix
    ./obs.nix
    ./obsidian.nix
    ./rustdesk_hm.nix
    ./staruml.nix
    ./zathura.nix
  ];
}
