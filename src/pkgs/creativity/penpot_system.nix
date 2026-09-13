# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/creativity/penpot_system.nix
# ──────────────────────────────────────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────────────
# This module handles two system concerns required for the local Penpot instance:
#
#   1. /etc/hosts entry — resolves design.penpot.local to 127.0.0.1
#
#   2. Caddy local CA trust — adds Caddy's generated root cert to the
#      system trust store so browsers accept https://design.penpot.local
#      without security warnings.
#
# ──────────────────────────────────────────────────────────────────────────────
# ── Migration note:
# ──────────────────────────────────────────────────────────────────────────────
# The networking.hosts entry and security.pki.certificateFiles entry here are
# Penpot-specific and intentionally scoped to this module.
#
# After a dedicated CypherOS local networking module is built, these
# declarations might migrate there. At that point:
#
#   - networking.hosts becomes a central registry of local service domains
#   - security.pki.certificateFiles becomes a shared list of trusted local CAs
#   - This module either imports from that networking module or is dissolved
#
# This module serves as the reference implementation for that pattern.
# See: ADR-004-hosts-file-pending-resolved.md from cypher-penpot Project(repo).
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.creativity;
  penpotCerts = cypherOsConstants.penpotCertificateFile;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.penpot.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # ── Local DNS resolution:
    # ──────────────────────────────────────────────────────────────────────────
    # Resolves design.penpot.local to localhost without a DNS server.
    # This is a manual /etc/hosts approach — intentionally simple.
    # The upgrade path to systemd-resolved stub zones is documented in
    # ADR-004.
    # ──────────────────────────────────────────────────────────────────────────
    networking.hosts = {
      "127.0.0.1" = [ "design.penpot.local" ];
    };

    # ──────────────────────────────────────────────────────────────────────────
    # ── Caddy local CA trust:
    # ──────────────────────────────────────────────────────────────────────────
    # Caddy generates a local CA on first run and stores the root
    # certificate at:
    #   <caddy-data-volume>/caddy/pki/authorities/local/root.crt
    #
    # Which on this machine currently resolves to:
    #
    #  /home/cypher-whisperer/DATA/FILES/DE_FILES/SHARED/APPS/Penpot/
    #  NEW_SCHOOL/PERSISTENT_INSTANCE_DATA/caddy/data/caddy/pki/authorities/
    #  local/root.crt
    #
    # IMPORTANT — bootstrap sequence:
    #   1. Run `docker compose up -d` first to let Caddy generate its CA.
    #   2. Verify the root.crt file exists at the path above.
    #   3. Then run `sudo nixos-rebuild switch` to apply this config.
    #   4. After rebuild, browsers on this machine will trust the cert.
    #
    # If Caddy is ever recreated and generates a new CA (rare — the caddy/data
    # volume is persistent), repeat step 3 to re-trust the new certificate.
    # ──────────────────────────────────────────────────────────────────────────
    security.pki.certificateFiles = [
      penpotCerts
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
        assertion = !(cfg.enable && cfg.penpot.enable) || builtins.pathExists penpotCerts;
        message = ''
          Penpot's Caddy CA cert not found at ${penpotCerts} — bootstrap Penpot's docker-compose stack first (see module header).
        '';
      }
    ];
  };
}
