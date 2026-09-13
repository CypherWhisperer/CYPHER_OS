# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/browser/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.pkgs.browser;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.browser.enable = lib.mkDefault (cypherOsProfile == "desktop");

    cypher-os.pkgs.browser.tor.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.browser.brave.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.browser.firefox.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.browser.mullvad.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.browser.librewolf.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.browser.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.tor.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.browser.tor.enable requires cypher-os.pkgs.browser.enable.
        '';
      }
      {
        assertion = cfg.brave.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.browser.brave.enable requires cypher-os.pkgs.browser.enable.
        '';
      }
      {
        assertion = cfg.firefox.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.browser.firefox.enable requires cypher-os.pkgs.browser.enable.
        '';
      }
      {
        assertion = cfg.mullvad.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.browser.mullvad.enable requires cypher-os.pkgs.browser.enable.
        '';
      }
      {
        assertion = cfg.librewolf.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.browser.librewolf.enable requires cypher-os.pkgs.browser.enable.
        '';
      }
    ];
  };
}
