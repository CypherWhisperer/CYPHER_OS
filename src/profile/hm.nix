# ──────────────────────────────────────────────────────────────────────────────
# src/profile/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# HM-context half of the profile module.
#
# Implements the osConfig ? null fallback pattern from ADR-024: on the
# nested cypher-nixos host, profile.active / lens.current are read from
# the NixOS graph via osConfig; on standalone lenses (no NixOS graph to
# nest under — Arch/Debian/Fedora/openSUSE, or the standalone cypher-nixos
# HM entry point used for fast iteration) they fall back to this graph's
# own config.cypher-os.*, which that host's home.nix must set explicitly.
#
# Resolved once here and exposed via _module.args, so CypherOS namespace
# modules can consume cypherOsProfile / cypherOsLens directly instead of
# re-deriving the osConfig fallback in every module that needs it.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  osConfig ? null,
  ...
}:

{
  imports = [ ./options.nix ];

  config._module.args = {
    cypherOsProfile =
      if osConfig != null then osConfig.cypher-os.profile.active else config.cypher-os.profile.active;

    cypherOsLens =
      if osConfig != null then osConfig.cypher-os.lens.current else config.cypher-os.lens.current;
  };
}
