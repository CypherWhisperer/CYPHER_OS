# ──────────────────────────────────────────────────────────────────────────────
# flake/hosts.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  inputs,
  system,
  nixpkgsOverlays,
  nixpkgsConfig,
}:
let
  values = import ../src/config/constants/values.nix;
  activeHostName = values.activeHostName;
  username = values.username;
in
{
  # ────────────────────────────────────────────────────────────────────────────
  # NIXOS SYSTEM CONFIGURATION.
  # ────────────────────────────────────────────────────────────────────────────
  # nixosConfigurations defines bootable NixOS systems.
  # Each key is the hostname — referenced with --flake .#<hostname>.
  #
  # lib.nixosSystem builds a full NixOS system from the module list.
  # The home-manager NixOS module (homeManagerModules.home-manager) integrates
  # Home Manager directly into `nixos-rebuild switch` — one command applies
  # both the system config and the user config.
  # ────────────────────────────────────────────────────────────────────────────
  ${activeHostName} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    # ──────────────────────────────────────────────────────────────────────────
    # specialArgs threads the `inputs` attrset into every NixOS module in
    # this configuration. This is the only way to make `inputs.*` available
    # inside configuration.nix without importing the flake directly there
    # (which would break modularity).
    #
    # The overlay registration in flake/nixpkgs_config.nix then reads:
    #   nixpkgs.overlays = [ inputs.* ];
    #
    # self makes the current flake available in all NixOS modules, including
    # Home Manager modules nested within it.
    # ──────────────────────────────────────────────────────────────────────────
    specialArgs = {
      inherit inputs;
      self = inputs.self;
    };

    modules = [
      {
        # ──────────────────────────────────────────────────────────────────────
        # Inject overlays into the NixOS pkgs instance; nixos-rebuild and HM
        # both see these.
        # ──────────────────────────────────────────────────────────────────────
        nixpkgs.overlays = nixpkgsOverlays;
        nixpkgs.config = nixpkgsConfig;
      }

      # ────────────────────────────────────────────────────────────────────────
      # The system-level configuration for this host
      # ────────────────────────────────────────────────────────────────────────
      ../hosts/nixos/configuration.nix

      # ────────────────────────────────────────────────────────────────────────
      # Integrate Home Manager into NixOS; Making `nixos-rebuild switch`
      # also apply the Home Manager config. No separate `home-manager switch`
      # follow up command needed when using this integration.
      # ────────────────────────────────────────────────────────────────────────
      inputs.home-manager.nixosModules.home-manager

      {
        # ──────────────────────────────────────────────────────────────────────
        # useGlobalPkgs: Home Manager uses the same nixpkgs instance as the
        # system — critically, this means the overlays applied in
        # flake/nixpkgs_config.nix are also visible inside Home Manager
        # Without it, HM would build its own pkgs without the overlay.
        # ──────────────────────────────────────────────────────────────────────
        home-manager.useGlobalPkgs = true;

        # ──────────────────────────────────────────────────────────────────────
        # useUserPackages: packages declared in home.packages are installed
        # into /etc/profiles/per-user/<user>/ rather than ~/.nix-profile.
        # This makes them available in GDM and system contexts.
        # ──────────────────────────────────────────────────────────────────────
        home-manager.useUserPackages = true;

        # ──────────────────────────────────────────────────────────────────────
        # Thread inputs into Home Manager modules too, in case any HM module
        # ever needs to reference a flake input directly.
        # ──────────────────────────────────────────────────────────────────────
        home-manager.extraSpecialArgs = {
          inherit inputs;
          self = inputs.self;
        };

        # ──────────────────────────────────────────────────────────────────────
        # The actual Home Manager configuration for cypher_whisperer.
        # This imports modules/home/default.nix.
        # ──────────────────────────────────────────────────────────────────────
        home-manager.users.${username} =
          {
            ...
          }:
          let
            values = import ../src/config/constants/values.nix;
          in
          {
            imports = [
              ./../src/home/default.nix
              inputs.catppuccin.homeModules.catppuccin
            ];

            # ──────────────────────────────────────────────────────────────────
            # Identity — must match users.users
            # ──────────────────────────────────────────────────────────────────
            home.username = values.username;
            home.homeDirectory = values.homeDirectory;

            # ──────────────────────────────────────────────────────────────────
            # DROPPED
            # ──────────────────────────────────────────────────────────────────
            # Neither `flake/hosts.nix` nor `flake/home-configurations.nix`
            # should ever set `cypher-os.profile.*`/`cypher-os.lens.*` directly:
            #
            #  - For `cypher-nixos`: `hosts/nixos/profile.nix` is already the
            #    sole authoritative setter (imported via `configuration.nix`),
            #    forwarded to the nested HM graph via `osConfig`.
            #    Nothing at this flake-wiring layer needs to touch it.
            #
            #  - For standalone lenses: each lens's own `hosts/<lens>/home.nix`
            #    is the authoritative setter, per ADR-024. Same principle —
            #    the flake-level aggregator's job is which modules go into which
            #    `nixosSystem`/`homeManagerConfiguration` call, not injecting
            #    inline profile config.
            # ──────────────────────────────────────────────────────────────────
            #cypher-os.profile.desktop.enable = true;
            # ──────────────────────────────────────────────────────────────────
          };

        # ──────────────────────────────────────────────────────────────────────
        # This tells HM to rename any conflicting existing files to .hm-bak
        # instead of refusing to proceed.
        # ──────────────────────────────────────────────────────────────────────
        # ──────────────────────────────────────────────────────────────────────
        # home-manager.backupCommand = "${pkgs.trash-cli}/bin/trash";
        # Alternative to backupFileExtension: instead of renaming conflicting
        # files to `<file>.hm-bak` in place, runs this command on each one.
        # Mutually exclusive in practice with backupFileExtension — pick one.
        #
        # Worth considering given a prev issue with ~/.config/gtk-4.0/assets:
        # trash-cli moves the file to a real trash can instead of leaving a
        # `.hm-bak` sibling that can itself go stale and cause the clobber loop
        # that's just been fixed.
        # Trade-off: one more package pulled in, and "undo" means digging
        # through trash instead of finding a `.hm-bak` right next to the
        # original.
        # ──────────────────────────────────────────────────────────────────────
        home-manager.backupFileExtension = "hm-bak";

        # ──────────────────────────────────────────────────────────────────────
        # Prints more detail during activation (each activation script's
        # internal steps, not just the top-level "Activating X").
        # Useful temporarily while debugging something — noisy for daily use.
        # Left off by default, flip on when needed.
        # ──────────────────────────────────────────────────────────────────────
        #home-manager.verbose = true;

        # ──────────────────────────────────────────────────────────────────────
        # Modules injected into EVERY user under home-manager.users.*
        # automatically — no need to list them per-user.
        #
        # Directly relevant to the "import catppuccin in every HM evaluation
        # context separately" pattern documented in
        # flake/home-configurations.nix: this option removes that duplication,
        # but only within the NixOS-module path (it has no effect on standalone
        # homeConfigurations, since sharedModules is itself a home-manager.*
        # NixOS option, not a home-manager.lib.homeManagerConfiguration one).
        #
        # Worth adopting once more users are added under home-manager.users —
        # with only cypher_whisperer today, it saves zero duplication right now,
        # so it's a "when you need it" option rather than an immediate win.
        # ──────────────────────────────────────────────────────────────────────
        #home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
      }
    ];
  };
}
