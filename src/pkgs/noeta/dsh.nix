# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/dsh.nix
# ──────────────────────────────────────────────────────────────────────────────
# DeepSeek Harness (dsh), exposed as a thin wrapper around a pinned npx call.
#
# This is NOT a package of dsh. Nix supplies only the Node runtime; npx fetches
# the pinned @deepseek-ai/dsh release on first use and caches it under
# ~/.npm/_npx, so later launches are fast and need no network.
#
#   - Upgrading means editing `dshVersion` below and following the runbook:
#       docs/project/runbooks/RBK_018_bump_the_pinned_dsh_version.md
#
#   - First launch after a version change fetches ~80 packages and takes
#     minutes; warm launches take about a second.
#
#   - `--yes` skips npx's install prompt. That consent is implicit: the
#     version is pinned in-repo.
#
#   - The release pins its own @deepseek-ai/* siblings, but some third-party
#     dependencies use semver ranges and no lockfile ships with the package.
#     Transitive resolution can therefore differ between machines or first-run
#     dates. Full packaging would remove that drift at the cost of a lockfile
#     and hash maintained per bump.
#
#   - The published package declares no `engines` field. Upstream's monorepo
#     targets Node ^22.19 or >=24, so the newer one is used here.
#
#   - Credentials (e.g. DEEPSEEK_API_KEY) are supplied through the environment
#     at runtime and are never declared in Nix.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;

  dshVersion = "0.2.0-rc.2";

  dsh = pkgs.writeShellApplication {
    name = "dsh";
    runtimeInputs = [ pkgs.nodejs_24 ];
    text = ''
      exec npx --yes @deepseek-ai/dsh@${dshVersion} "$@"
    '';
  };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.dsh.enable) {
    home.packages = [ dsh ];
  };
}
