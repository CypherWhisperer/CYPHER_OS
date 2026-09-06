# ──────────────────────────────────────────────────────────────────────────────
# src/CATEGORY/options.nix
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# NOTE: Each package is its own leaf as per ADR_023, so multiple independent
# packages don't collapse into one shared switch, unless that's explicitly
# desired (i.e., a set of packages that are ideally groupable.)
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os. ... = {
    enable = lib.mkEnableOption " ";

    # ──────────────────────────────────────────────────────────────────────────
    # IF CATEGORY SPANS BOTH DESKTOP AND SERVER PROFILES AND HAS GUI PACKAGES
    # INCLUDE A gui NAMESPACE (i.e., CATEGORY) SUB-BRANCH.
    # ──────────────────────────────────────────────────────────────────────────
    #gui = {
    #  enable = lib.mkEnableOption " ... GUI (Graphical User Interface) Packages ...";
    #}
  }
}
