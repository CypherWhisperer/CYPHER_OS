# flake/default.nix
#
# Builds the shared pkgs instance from the SSOT nixpkgs-config, then
# composes hosts.nix, home-configurations.nix, and devshells.nix into
# the final flake outputs attrset.

{ inputs }:

let
  # system: the CPU architecture + OS pair Nix uses to select packages.
  # x86_64-linux covers standard 64-bit Intel/AMD Linux machines.
  # If you ever add an ARM machine, you'd add "aarch64-linux" entries.
  system = "x86_64-linux";

  nixpkgsCfg = import ./nixpkgs-config.nix { inherit inputs; };

  # pkgs is instantiated here for use in standalone homeConfigurations.
  # The NixOS nixosConfigurations path does NOT use this pkgs.

  # NixOS builds its own pkgs internally (with the overlays applied via
  # nixpkgs.overlays in configuration.nix). Using this pkgs in
  # nixosConfigurations would bypass the overlay, which is why
  # homeConfigurations.pkgs and nixosConfigurations.pkgs are intentionally separate.

  # pkgs: the nixpkgs package set for the system, with unfree allowed.
  # Declaring it here means we reference it once rather than repeating
  # the same nixpkgs.legacyPackages.${system} call everywhere.
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = nixpkgsCfg.overlays;
    config = nixpkgsCfg.config;
  };

in

{
  nixosConfigurations = import ./hosts.nix {
    inherit inputs system;
    nixpkgsOverlays = nixpkgsCfg.overlays;
    nixpkgsConfig = nixpkgsCfg.config;
  };

  homeConfigurations = import ./home-configurations.nix {
    inherit inputs pkgs;
  };

  devShells.${system} = import ./devshells.nix {
    inherit inputs system pkgs;
  };
}
