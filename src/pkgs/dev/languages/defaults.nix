# ──────────────────────────────────────────────────────────────────────────────
# src/dev/languages/defaults.nix
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
    cypher-os.pkgs.dev.languages.enable = lib.mkDefault cfg.enable;

    cypher-os.pkgs.dev.languages.go.enable = lib.mkDefault cfg.languages.enable;
    cypher-os.pkgs.dev.languages.php.enable = lib.mkDefault cfg.languages.enable;
    cypher-os.pkgs.dev.languages.bash.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.cCpp.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.dart.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.jsTs.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.kotlin.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.lua.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.nix.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.python.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.rust.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.zig.enable = lib.mkDefault cfg.language.enable;
    cypher-os.pkgs.dev.languages.d2.enable = lib.mkDefault cfg.language.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.languages.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.dev.languages.enable requires cypher-os.pkgs.dev.enable.
        '';
      }

      {
        assertion = cfg.languages.go.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.go.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.php.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.php.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.bash.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.bash.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.cCpp.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.cCpp.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.dart.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.dart.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.jsTs.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.jsTs.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.kotlin.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.kotlin.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.lua.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.lua.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.nix.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.nix.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.python.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.python.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.rust.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.rust.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.zig.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.zig.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
      {
        assertion = cfg.languages.d2.enable -> cfg.languages.enable;
        message = ''
          cypher-os.pkgs.dev.languages.d2.enable requires cypher-os.pkgs.dev.languages.enable.
        '';
      }
    ];
  };
}
