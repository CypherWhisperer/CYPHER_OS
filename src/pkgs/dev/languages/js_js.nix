# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/js_ts.nix
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# PRISMA / NODE NOTE:
# ──────────────────────────────────────────────────────────────────────────────
# NixOS has a non-standard filesystem layout (no /lib/ld-linux.so), so Prisma
# cannot use its default strategy of downloading precompiled engine binaries
# from binaries.prisma.sh at install time — those binaries are ELF executables
# linked against glibc paths that don't exist on NixOS.
#
# The fix: declare prisma-engines from nixpkgs and expose the binary paths via
# home.sessionVariables. Prisma reads these env vars before attempting any
# download, so the download is skipped entirely.
#
# home.sessionVariables vs shellHook
#   shellHook only fires inside `nix develop` / `nix-shell` sub-shells.
#   home.sessionVariables writes into your shell's login environment (via
#   ~/.nix-profile/etc/profile.d/hm-session-vars.sh), so these vars are
#   present in every terminal, every project, every tool that inherits the
#   environment — including Cursor, Ghostty tabs, and any Node process
#   that spawns Prisma. No per-project boilerplate needed.
#
# Version alignment:
#   nixpkgs keeps nodePackages.prisma and prisma-engines on compatible
#   versions. If a project pins a specific Prisma CLI version in package.json
#   that diverges significantly from the nixpkgs revision in your flake.lock,
#   you may see API mismatch warnings. Handle that at the project level with a
#   devShell override — it is an edge case, not the common path.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.languages;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.jsTs.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # PNPM.
      # ────────────────────────────────────────────────────────────────────────
      pnpm # Fast, disk-efficient package manager (preferred over npm)

      # ────────────────────────────────────────────────────────────────────────
      # NODE.
      # ────────────────────────────────────────────────────────────────────────
      # nodejs_22: Node.js LTS v22. Required for your Next.js and TypeScript
      # work.  Includes npm. For version management across projects, consider
      # using  fnm (Fast Node Manager) or nix shells with pinned Node versions.
      # Usage: node --version   npm --version
      #
      # ────────────────────────────────────────────────────────────────────────
      # LATEST VERSION
      # ────────────────────────────────────────────────────────────────────────
      #nodejs          # Node.js runtime — provides `node` and `npm`
      # ────────────────────────────────────────────────────────────────────────
      # LTS VERSION.
      # ────────────────────────────────────────────────────────────────────────
      # As of flake update 2026-06-05, nodejs 20.20.2 is marked as insecure.
      #nodejs_20 # pinned to LTS
      # ────────────────────────────────────────────────────────────────────────
      nodejs_22

      # ────────────────────────────────────────────────────────────────────────
      # BUN.
      # ────────────────────────────────────────────────────────────────────────
      # bun: fast JavaScript runtime, bundler, transpiler and package manager
      # all in one. Subset of Node.js
      # API compatibility with much faster startup and install times. Good for:
      #   - Scripts where startup speed matters
      #   - Workspaces where you want faster `bun install` vs `npm install`
      #   - Running TypeScript files directly: bun script.ts
      # Not a full Node replacement yet, but increasingly capable.
      # ────────────────────────────────────────────────────────────────────────
      bun

      # ────────────────────────────────────────────────────────────────────────
      # DENO.
      # ────────────────────────────────────────────────────────────────────────
      # deno: secure-by-default JavaScript/TypeScript runtime. Explicit
      # permission model (no file/network access without flags),
      # built-in formatter/linter, TypeScript without a build step. Learn its
      # philosophy alongside Node/Bun. Usage: deno run --allow-net script.ts
      # ────────────────────────────────────────────────────────────────────────
      deno

      # ────────────────────────────────────────────────────────────────────────
      # Prisma CLI — the `prisma` binary used by `bunx prisma`, `npx prisma`,
      # etc. Paired with prisma-engines below; nixpkgs keeps them
      # version-aligned.
      #
      #nodePackages.prisma # <- nodePackages removed due to maintenance issues
      # ────────────────────────────────────────────────────────────────────────
      prisma_7

      # ────────────────────────────────────────────────────────────────────────
      # Prisma engine binaries — Nix-packaged so no ELF download is attempted.
      # The four binaries exposed here cover all Prisma operations:
      #  - schema-engine  →  `prisma migrate`, `prisma db push`
      #  - query-engine   →  runtime query execution (binary mode)
      #
      #  - libquery_engine → runtime query execution (library/node-api mode,
      #                      default)
      #
      #  - prisma-fmt     →  `prisma format`, editor schema formatting
      # ────────────────────────────────────────────────────────────────────────
      prisma-engines
    ];

    # ──────────────────────────────────────────────────────────────────────────
    # PRISMA ENGINE PATH WIRING.
    # ──────────────────────────────────────────────────────────────────────────
    # These four variables are the canonical interface between the Prisma CLI
    # and the engine binaries. When set, Prisma skips all download logic and
    # uses the paths directly — which is exactly what we want on NixOS.
    #
    # The `${pkgs.prisma-engines}` interpolation is resolved at `home-manager
    # switch` time and written as a literal store path (e.g.
    # /nix/store/abc123-prisma-engines-5.x.x/bin/schema-engine) into your
    # shell environment file. It will not drift between switches unless you
    # explicitly update your flake inputs.
    # ──────────────────────────────────────────────────────────────────────────
    home.sessionVariables = {
      PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
      PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
      PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
      PRISMA_FMT_BINARY = "${pkgs.prisma-engines}/bin/prisma-fmt";
    };
  };
}
