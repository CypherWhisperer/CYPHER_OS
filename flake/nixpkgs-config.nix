# flake/nixpkgs-config.nix
#
# Single source of truth for overlays and nixpkgs.config.
# Consumed by BOTH flake/hosts.nix (nixosConfigurations) and
# flake/home-configurations.nix (standalone homeConfigurations) —
# this is what makes pkgs.claude-desktop (and other overlays) resolve
# identically in both:
#  `nixos-rebuild switch --flake .#cypher-nixos`
#  `home-manager switch --flake .#cypher_whisperer@cypher-nixos`.
#
# Add a new overlay ONCE, here. Never duplicate an overlay list again.

{ inputs }:

{
  overlays = [
    # Injects givel overlays array into the package set. After this, any
    # module receiving pkgs can access everything the overlays provide.
    inputs.nix-vscode-extensions.overlays.default
    inputs.nur.overlays.default
    inputs.claude-desktop.overlays.default
    (import ./overlays/anydesk.nix)
  ];

  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "ventoy-1.1.12"

      # Logseq pins electron_39 (39.8.10), which nixpkgs has marked EOL/insecure.
      # Upstream hasn't cut a release bumping the Electron pin yet.
      # Tracked at nixpkgs#528213. Revisit when Logseq releases a new version.
      # Electron override attempts (34, 36, 37, 38) all failed — removed/insecure.
      "electron-39.8.10"
    ];
  };
}
