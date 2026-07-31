# flake/home-configurations.nix
#
# Standalone Home Manager configurations — for non-NixOS hosts (Arch,
# Debian, Fedora, openSUSE), and as a dev-workflow convenience on NixOS.
# Applied with: `home-manager switch --flake .#<user>@<host>`

{
  inputs,
  pkgs,
}:

{
  # ── Standalone Home Manager Configurations ────────────────────────────────
  # homeConfigurations are for non-NixOS hosts (Arch, Debian, Fedora, OpenSuse).
  # Applied with: home-manager switch --flake .#cypher-whisperer@<host>

  # On these hosts, the OS manages the system level. Home Manager manages
  # only the user environment (packages, dotfiles, dconf settings, etc).

  # The cypher-nixos entry here is a convenience — allows running HM standalone

  "cypher-whisperer@cypher-nixos" = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;

    # The standalone Home Manager configurations also need self
    # NOTE: it is `extraSpecialArgs` here, not `specialArgs`.
    extraSpecialArgs = {
      inherit inputs;
      self = inputs.self;
    };

    modules = [
      ../modules/home/default.nix

      # Every flake input that contributes HM modules (catppuccin, future
      # ones) must be imported in EVERY HM evaluation context separately —
      # importing pkgs overlays does not import HM module option
      # declarations. See flake/nixpkgs-config.nix for the overlay half
      # of this same principle.
      inputs.catppuccin.homeModules.catppuccin

      # MORE ON THE ABOVE
      # inputs.catppuccin.homeModules.catppuccin must be imported here explicitly,
      # mirroring the import in the NixOS-integrated path (flake.nix nixosConfigurations
      # block, under home-manager.users.cypher-whisperer.imports).
      #
      # Why this is necessary:
      # The catppuccin flake input is declared at the top of this flake and passed
      # through outputs, but declaring an input does not automatically make its HM
      # modules available — each Home Manager evaluation context (NixOS-integrated vs
      # standalone homeConfigurations) is an independent module system instantiation.
      # A module imported in one context is invisible to the other unless explicitly
      # re-imported. The NixOS path had it; the standalone path did not.
      #
      # Effect of its absence:
      # Any module in the CypherOS HM tree that references `catppuccin.*` options
      # (currently vscode.nix) causes a hard evaluation failure in the standalone
      # context — "The option `catppuccin' does not exist" — because the option
      # declarations that catppuccin's HM module provides were never loaded.
      # Critically, this failure is silent during normal `nixos-rebuild switch`
      # because that path uses nixosConfigurations, not homeConfigurations. The
      # standalone path was broken without any visible symptom until directly evaluated.
      #
      # Effect of its addition:
      # The standalone homeConfigurations entry now evaluates cleanly and produces
      # a configuration identical to the NixOS-integrated path. Both contexts are
      # now in sync — any catppuccin.* option set in any HM module resolves correctly
      # regardless of which evaluation path is used.
      #
      # Future implications:
      # This is a pattern to internalize: every flake input that contributes HM
      # modules (catppuccin, nix-vscode-extensions via overlays, any future HM
      # module flake) must be explicitly imported in EVERY Home Manager evaluation
      # context that uses options it declares. When adding new HM module flakes in
      # the future, the checklist is:
      #   1. Add to flake inputs (with inputs.nixpkgs.follows = "nixpkgs")
      #   2. Import the HM module in nixosConfigurations home-manager.users.*.imports
      #   3. Import the HM module in homeConfigurations modules — this line
      # Skipping step 3 produces the same silent breakage discovered here.
      #
      # This was a finding as a result of diagnosing devenv+direnv setup for the
      # XAMPP NixOS alternative setup. The following commands are what triggered the
      # error leading to the resolution:
      # `nix eval .#homeConfigurations."cypher-whisperer@cypher-nixos".config.programs.direnv.enable 2>&1`
      # `nix eval .#homeConfigurations."cypher-whisperer@cypher-nixos".config.programs.direnv.nix-direnv.enable 2>&1`

      {
        home.username = "cypher-whisperer";
        home.homeDirectory = "/home/cypher-whisperer";
        cypher-os.profile.desktop.enable = true;
      }
    ];
  };

  # Future hosts — uncomment and add host-specific home.nix progressively:
  # "cypher-whisperer@arch" = inputs.home-manager.lib.homeManagerConfiguration {
  #   inherit pkgs;
  #   extraSpecialArgs = { inherit inputs; self = inputs.self; };
  #   modules = [
  #     ../hosts/arch/home.nix
  #     { home.username = "cypher-whisperer"; home.homeDirectory = "/home/cypher-whisperer"; }
  #   ];
  # };
}
