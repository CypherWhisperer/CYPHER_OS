# flake/hosts.nix
#
# nixosConfigurations — bootable NixOS systems.
# Each key is a hostname, referenced with --flake .#<hostname>.

{
  inputs,
  system,
  nixpkgsOverlays,
  nixpkgsConfig,
}:

{
  # ── NixOS System Configurations ─────────────────────────────────────────
  # nixosConfigurations defines bootable NixOS systems.
  # Each key is the hostname — referenced with --flake .#<hostname>.
  #
  # lib.nixosSystem builds a full NixOS system from the module list.
  # The home-manager NixOS module (homeManagerModules.home-manager) integrates
  # Home Manager directly into `nixos-rebuild switch` — one command applies
  # both the system config and the user config.

  cypher-nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    # specialArgs threads the `inputs` attrset into every NixOS module in
    # this configuration. This is the only way to make `inputs.*` available
    # inside configuration.nix without importing the flake directly there
    # (which would break modularity).

    # The overlay registration in flake/nixpkgs-config.nix then reads:
    #   nixpkgs.overlays = [ inputs.* ];

    # self makes the current flake available in all NixOS modules, including
    # Home Manager modules nested within it.
    specialArgs = {
      inherit inputs;
      self = inputs.self;
    };

    modules = [
      {
        # Inject overlays into the NixOS pkgs instance; nixos-rebuild and HM both see these.
        nixpkgs.overlays = nixpkgsOverlays;
        nixpkgs.config = nixpkgsConfig;
      }

      # The system-level configuration for this host
      ../hosts/nixos/configuration.nix

      # Integrate Home Manager into NixOS; Making `nixos-rebuild switch`
      # also apply the Home Manager config. No separate `home-manager switch`
      # follow up command needed when using this integration.
      inputs.home-manager.nixosModules.home-manager
      {
        # useGlobalPkgs: Home Manager uses the same nixpkgs instance as the
        # system — critically, this means the overlays applied in
        # flake/nixpkgs-config.nix are also visible inside Home Manager
        # Without it, HM would build its own pkgs without the overlay.
        home-manager.useGlobalPkgs = true;

        # useUserPackages: packages declared in home.packages are installed
        # into /etc/profiles/per-user/<user>/ rather than ~/.nix-profile.
        # This makes them available in GDM and system contexts.
        home-manager.useUserPackages = true;

        # Thread inputs into Home Manager modules too, in case any HM module
        # ever needs to reference a flake input directly.
        home-manager.extraSpecialArgs = {
          inherit inputs;
          self = inputs.self;
        };

        # The actual Home Manager configuration for cypher-whisperer.
        # This imports modules/home/default.nix.
        home-manager.users.cypher-whisperer =
          {
            config,
            pkgs,
            lib,
            ...
          }:

          {
            imports = [
              ../modules/home/default.nix
              inputs.catppuccin.homeModules.catppuccin
            ];

            # Identity — must match users.users
            home.username = "cypher-whisperer";
            home.homeDirectory = "/home/cypher-whisperer";

            # Activate the desktop profile; This cascades all app/DE/DM defaults.
            # Override any individual option below this line to deviate from the profile.
            cypher-os.profile.desktop.enable = true;

            # Example overrides (uncomment to use):
            # cypher-os.de.gnome.enable    = false;
            # cypher-os.de.hyprland.enable = true;
            # cypher-os.apps.gaming.enable = false;
          };

        # This tells HM to rename any conflicting existing files to .hm-bak
        # instead of refusing to proceed.
        home-manager.backupFileExtension = "hm-bak";
      }
    ];
  };
}
