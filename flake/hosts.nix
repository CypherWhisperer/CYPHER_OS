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

        # The actual Home Manager configuration for cypher_whisperer.
        # This imports modules/home/default.nix.
        home-manager.users.cypher_whisperer =
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
            home.username = "cypher_whisperer";
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

        # home-manager.backupCommand = "${pkgs.trash-cli}/bin/trash";
        # Alternative to backupFileExtension: instead of renaming conflicting
        # files to `<file>.hm-bak` in place, runs this command on each one.
        # Mutually exclusive in practice with backupFileExtension — pick one.
        #
        # Worth considering given our prev issue with ~/.config/gtk-4.0/assets:
        # trash-cli moves the file to a real trash can instead of leaving a
        # `.hm-bak` sibling that can itself go stale and cause the clobber loop
        # that's just been fixed.
        # Trade-off: one more package pulled in, and "undo" means digging through
        # trash instead of finding a `.hm-bak` right next to the original.

        # home-manager.verbose = true;
        # Prints more detail during activation (each activation script's internal
        # steps, not just the top-level "Activating X").
        # Useful temporarily while debugging something — noisy for daily use.
        # Left off by default, flip on when needed.

        # home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
        # Modules injected into EVERY user under home-manager.users.*
        # automatically — no need to list them per-user.
        #
        # Directly relevant to the "import catppuccin in every HM evaluation context separately"
        # pattern documented in flake/home-configurations.nix: this option
        # removes that duplication, but only within the NixOS-module path
        # (it has no effect on standalone homeConfigurations, since sharedModules
        # is itself a home-manager.* NixOS option, not a
        # home-manager.lib.homeManagerConfiguration one).
        #
        # Worth adopting once more users are added under home-manager.users —
        # with only cypher_whisperer today, it saves zero duplication right now,
        # so it's a "when you need it" option rather than an immediate win.
      }
    ];
  };
}
