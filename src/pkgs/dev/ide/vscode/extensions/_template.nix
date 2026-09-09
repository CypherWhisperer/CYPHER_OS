# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/{lang,devops,baseline}/*.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# ──────────────────────────────────────────────────────────────────────────────
# NOTE ON EXTENSIONS TIERS:
# ──────────────────────────────────────────────────────────────────────────────
#  Tier 1 (nixpkgs): extensions available as pkgs.vscode-extensions.*
#    Managed by Nix — reproducible, no network call at activation time.
#
#  Tier 2 (marketplace): extensions not in nixpkgs, fetched from
#    pkgs.nix-vscode-extensions.vscode-marketplace.
#
#    Previous approach via Open VSX/ VS Marketplace (via
#    vscode-utils.buildVscodeMarketplaceExtension) was ruled over due to issues
#    with building (hash mismatches).
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
 ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;

  # ────────────────────────────────────────────────────────────────────────────
  # nix-vscode-extensions aliases
  # ────────────────────────────────────────────────────────────────────────────
  # These give us short names to reach the two registries.
  #
  # vscode-marketplace: Microsoft's official registry. Use for extensions that
  #                     are exclusive to it (proprietary, AI tools, etc.)
  #
  # open-vsx: The vendor-neutral open-source registry. Prefer this when an
  #           extension is available on both — no Microsoft ToS concerns, and
  #           the extension is byte-for-byte identical in most cases.
  #
  # ────────────────────────────────────────────────────────────────────────────
  # IMPORTANT: publisher and extension names are ALWAYS fully lowercase
  # in Nix attribute paths, even when the marketplace shows mixed case.
  # e.g. "Prisma" publisher → prisma.prisma, "fwcd" → fwcd.kotlin
  # ────────────────────────────────────────────────────────────────────────────
  vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable && cfg.extensions.{lang,devops,...}.LEAF.enable) {

      # ────────────────────────────────────────────────────────────────────────
      # Extensions are intentionally declared at the TOP LEVEL
      # (not profiles.default.extensions) as a workaround for the home-manager
      # regression introduced in commit b593765 (Feb 2026), which broke
      # extension loading when using profiles.default.extensions. HM routes
      # this to the default profile internally. A deprecation warning is
      # emitted at build time — it is cosmetic and can be ignored until
      # upstream reverts or properly fixes the regression.
      #
      # Track: https://github.com/nix-community/home-manager/issues/8793
      #
      # Declared at programs.vscode.extensions (top-level) instead of
      # programs.vscode.profiles.default.extensions — workaround for HM
      # regression b593765 (Feb 2026). HM still routes this to the default
      # profile internally.
      #
      # A build-time deprecation warning is emitted; it is cosmetic,
      # ignore it:
      #   trace: warning: The option `programs.vscode.extensions' ... has been
      #   renamed to
      #   `programs.vscode.profiles.default.extensions'.
      # Track: https://github.com/nix-community/home-manager/issues/8793
      # ────────────────────────────────────────────────────────────────────────
      programs.vscode.extensions = with pkgs.vscode-extensions; [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.* e.g.,
        # naumovs.color-highlight
        # ──────────────────────────────────────────────────────────────────────
      ]
      ++[
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
        # No sha256 needed — hashes are pre-computed in the flake's
        # JSON cache. To update all of these to their latest versions:
        #    nix flake update nix-vscode-extensions
        #
        # Naming convention: vscMkt.<publisher>.<extension-name>
        # (all lowercase)
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # NOTE: Nix attribute names cannot start with a digit. For package
        # Names with digits, use the  string-subscript form:
        #   attrset."string-key" instead of attrset.identifier; e.g.,
        #
        #   vscMkt."1yib".rust-bundle
        # ──────────────────────────────────────────────────────────────────────
      ];

      # ────────────────────────────────────────────────────────────────────────
      # userSettings: written to VSCode's settings.
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: actual deployment is handled by ../core_config.nix, leaf files
      # simply contribute to the attrset. Check comment block in ../options.nix
      # ────────────────────────────────────────────────────────────────────────
      cypher-os.pkgs.dev.ide.vscode._sharedSettings = {
      };
    };
}
