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
  };
}
