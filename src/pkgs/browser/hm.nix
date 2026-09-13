# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# NOTE: NUR REQUIREMENT.
# ──────────────────────────────────────────────────────────────────────────────
#   Firefox and LibreWolf extension management requires the NUR overlay.
#
#   In flake.nix:
#     inputs.nur.url = "github:nix-community/NUR";
#
#   In nixpkgs config:
#     nixpkgs.overlays = [ inputs.nur.overlays.default ];
#
# ──────────────────────────────────────────────────────────────────────────────
# FLEET USAGE GUIDE.
# ──────────────────────────────────────────────────────────────────────────────
# Browser            | Use for
# ──────────────────────────────────────────────────────────────────────────────
# Firefox            | Daily driver — dev work, web apps, authenticated sessions
# Brave              | Alternative daily driver; (hardened by default.)
# LibreWolf          | Alternative daily driver; stricter defaults than Firefox
# Mullvad Browser    | Sensitive sessions; research, financial, privacy-critical
# Tor Browser        | Anonymity-required sessions; .onion, high-stakes comms
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  imports = [
    ./options.nix
    ./defaults.nix
    ./firefox.nix
    ./librewolf.nix
    ./mullvad.nix
    ./tor_hm.nix
    ./brave_hm.nix
  ];
}
