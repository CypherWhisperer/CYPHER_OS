# ──────────────────────────────────────────────────────────────────────────────
# src/dev/arduino/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev;
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    # cypher-os.pkgs.dev.arduino.enable = lib.mkDefault cfg.enable; #overriden
    cypher-os.pkgs.dev.arduino.enable = lib.mkDefault false;

    cypher-os.pkgs.dev.arduino.ide.enable = lib.mkDefault cfg.arduino.enable;
    cypher-os.pkgs.dev.arduino.ota.enable = lib.mkDefault cfg.arduino.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.arduino.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.dev.arduino.enable requires cypher-os.pkgs.dev.enable.
        '';
      }

      {
        assertion = cfg.arduino.ide.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.dev.arduino.ide.enable requires cypher-os.pkgs.dev.arduino.enable.
        '';
      }
      {
        assertion = cfg.arduino.ota.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.dev.arduino.ota.enable requires cypher-os.pkgs.dev.arduino.enable.
        '';
      }
    ];
  };
}
