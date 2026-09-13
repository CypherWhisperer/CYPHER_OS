# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/affine_system.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.productivity;
  affineCerts = cypherOsConstants.affineCertificateFile;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.affine.enable) {
    networking.hosts = {
      "127.0.0.1" = [ "affine.local" ];
    };

    security.pki.certificateFiles = [
      affineCerts
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # Without this assertion, if this file is ever missing when someone runs
    # `nixos-rebuild switch` (not just `build`), the failure surfaces as a
    # cryptic `buildcatrust`/Python traceback deep in a derivation log.
    #
    # This assertion entry in checks the certificate files existence with
    # `builtins.pathExists affineCerts` and fails with a clear message pointing
    # at the bootstrap sequence, instead of letting it fall through to
    # nss-cacert's internals:
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = !(cfg.enable && cfg.affine.enable) || builtins.pathExists affineCerts;
        message = ''
          AFFiNE's Caddy CA cert not found at ${affineCerts} — bootstrap AFFiNE's docker-compose stack first (see penpot_system.nix module header).
        '';
      }
    ];
  };
}
