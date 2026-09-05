# ──────────────────────────────────────────────────────────────────────────────
# src/ ... /{hm,system}.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, pkgs, config, cypherOsProfile, ... }:

let
  cfg = config.cypher-os. ...;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [

    # ──────────────────────────────────────────────────────────────────────────
    # Packages eligible for both Server and Desktop Profile
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf cfg.enable {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    (lib.mkIf (cfg.enable && cfg. ... .enable) {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Desktop Profile (GUI subset)
    # ──────────────────────────────────────────────────────────────────────────
    # Each package is its own leaf under gui.*, so future additions don't
    # collapse into one shared switch, unless that's explicitly desired
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable && cfg. ... .enable) {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # Packages ONLY eligible for Server Profile
    # ──────────────────────────────────────────────────────────────────────────
    (lib.mkIf (cypherOsProfile == "server" && cfg.enable) {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    (lib.mkIf (cypherOsProfile == "server" && cfg.enable && cfg. ... .enable) {
      # Logic, e.g
      #home.packages = with pkgs; [
      #];

      # OR
      #environment.systemPackages = with pkgs; [
      #];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # CONFIGURATION DEFAULTS
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: pick ONE shape for the category's own top-level enable, don't leave
    # both:
    #
    #   Both-profile category:
    #     cypher-os. ... .enable = lib.mkDefault true; # i.e., no profile gating
    #
    #   Desktop-only category:
    #     cypher-os. ... .enable = lib.mkDefault (cypherOsProfile == "desktop");
    #     — pair with the matching assertion below.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os. ... .enable = lib.mkDefault (cypherOsProfile == "desktop");
      cypher-os. ... .enable = lib.mkDefault ... ;
    }

    {
      assertions = [
        {
          assertion = cfg ... .enable -> ... ;
          message = ''
            cypher-os. ... .enable requires ... .
          '';
        }


        {
          # ────────────────────────────────────────────────────────────────────
          # Stated once here — every leaf under gui.* inherits this via
          # the leaf-implies-gui.enable assertion below, transitively.
          # ────────────────────────────────────────────────────────────────────
          assertion = cfg. ... .gui.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os. ... .gui.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
