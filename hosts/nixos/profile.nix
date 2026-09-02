# ──────────────────────────────────────────────────────────────────────────────
# hosts/nixos/profile.nix
# ──────────────────────────────────────────────────────────────────────────────
# Host-owned profile declaration for cypher-nixos. This is the one place
# cypher-os.profile.active / lens.current are actually SET on this
# host — src/profile/system.nix only declares and re-exposes
# ──────────────────────────────────────────────────────────────────────────────

{ ... }:

{
  cypher-os.profile.active = "desktop";
  cypher-os.lens.current = "nixos";
}
