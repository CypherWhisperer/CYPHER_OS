{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.cypher-os.apps.dev.languages.go;
in
{
  config =
    lib.mkIf
      (config.cypher-os.apps.dev.enable && config.cypher-os.apps.dev.languages.enable && cfg.enable)
      {
        # ───────────────────────────────────────────────────────────────────────────
        programs.go = {
          enable = true;
          package = cfg.package; # or  pkgs.go_1_26 / pkgs.go_1_27 as needed

          # packages = { ... };  # vendored GOPATH packages (rarely needed with modules)

          env = {
            # ──────────────────────────────────────────────────────────────────────
            # Common useful settings (all go env vars are supported via freeform)
            # ──────────────────────────────────────────────────────────────────────
            GOPATH = "${config.home.homeDirectory}/${cfg.goPath}";
            GOPRIVATE = cfg.goPrivate;
            # GOSUMDB = "sum.golang.org";
            # GOPROXY = "https://proxy.golang.org,direct";  # or private proxy
            # GOFLAGS = "-mod=readonly";  # example
          }
          // cfg.extraEnv;

          telemetry.mode = cfg.telemetry;
          # date = "1970-01-01";  # only relevant when mode = "on"
        };

        # ──────────────────────────────────────────────────────────────────────────
        # Editor/CLI-facing tooling. gopls and delve are the load-bearing two
        # (both editors assume it's on PATH) — everything else is quality-of-life.
        #
        # Kept as a flat list rather than threaded through `cfg.extraTools` defaults
        # so it's visible in one place what "Go support" actually pulls in.
        # ──────────────────────────────────────────────────────────────────────────
        home.packages =
          with pkgs;
          [
            # ──────────────────────────────────────────────────────────────────────
            # CORE
            # ──────────────────────────────────────────────────────────────────────

            # ──────────────────────────────────────────────────────────────────────
            # go: Compiler, module tooling, test runner, formatter foundation,
            #     standard build ecosystem.
            # ──────────────────────────────────────────────────────────────────────
            go

            gopls # official language server
            delve # debugger (dlv) — backs both editors' DAP integration.

            # ──────────────────────────────────────────────────────────────────────
            # FORMATTING / LINTING / STATIC ANALYSIS
            # ──────────────────────────────────────────────────────────────────────

            # golines # long-line reformatter

            # ──────────────────────────────────────────────────────────────────────
            # gofumpt: stricter formatter (gofmt superset).
            # wired into both editors' formatters.
            # ──────────────────────────────────────────────────────────────────────
            gofumpt

            # ──────────────────────────────────────────────────────────────────────
            # gotools: Nixpkgs bundle providing common Go development utilities
            # (goimports, godoc, stringer, etc). exact included executables can
            # vary by nixpkgs revision.
            #
            # Wired into gopls (`formatting.gofumpt`) and Neovim's `conform.nvim`,
            # so one formatting standard applies everywhere.
            #
            # goimports specifically is used by Neovim's formatter chain.
            # ──────────────────────────────────────────────────────────────────────
            gotools

            gomodifytags # struct tag add/remove — used by both editors' code actions
            gotests # table-driven test scaffolding
            impl # interface method stub generation
            govulncheck # vulnerability scanning against the Go vuln DB

            # ──────────────────────────────────────────────────────────────────────
            # Linting / static analysis
            # ──────────────────────────────────────────────────────────────────────

            # revive # Configurable style linter, especially useful when a project adopts it.

            # ──────────────────────────────────────────────────────────────────────
            # golangci-lint: meta-linter;
            # gopls.ui.diagnostic.staticcheck covers most of it already,
            # but golangci-lint adds format-on-run (`golangci-lint fmt`) and org-wide
            # .golangci.yml policy support
            #
            # It is a repo-level multi-linter runner; best controlled by project `.golangci.yml`
            # It aggregates many analyzers; also has a `fmt` subcommand.
            #
            # Installed for CI-parity and terminal use even though `gopls`' embedded
            # staticcheck covers live in-editor linting already — see `vscode.nix`.
            # ──────────────────────────────────────────────────────────────────────
            golangci-lint

            # ──────────────────────────────────────────────────────────────────────
            # staticcheck: Standalone static analysis CLI; do not run redundantly on
            # each save if `gopls.staticcheck = true`
            #
            # Would provide a `staticcheck` binary independent of gopls. Redundant —
            # `gopls` already embeds the full `staticcheck` analyzer suite via
            # `ui.diagnostic.staticcheck`.
            #
            # Only worth adding if `staticcheck` needs to run somewhere gopls isn't
            # (e.g. a CI step outside golangci-lint.)
            # ──────────────────────────────────────────────────────────────────────
            # staticcheck

            # ──────────────────────────────────────────────────────────────────────
            # air: live-reload runner (for long-running Go services) —  for service dev.
            # Only relevant once an actual long-running service (vs. CLI tools/libraries)
            # is under active development.
            # ──────────────────────────────────────────────────────────────────────
            # air

            # ──────────────────────────────────────────────────────────────────────
            # TESTING/ GENERATION HELPERS
            # ──────────────────────────────────────────────────────────────────────
            gotests # Generates test scaffolding. # Backs "Generate Unit Tests"
            gomodifytags # Add/remove struct field tags for bothe editors.
            impl # Generates interface implementation method stubs.

            # ──────────────────────────────────────────────────────────────────────
            # OPTIONAL BUT COMMON FOR SERIOUS DEV SESSIONS.
            # ──────────────────────────────────────────────────────────────────────

            # ──────────────────────────────────────────────────────────────────────
            # govulncheck: Checks reachable code against known Go vulnerabilities.
            # Installed for terminal/CI use; the corresponding gopls codelens is
            # left off by default (see `vscode.nix`) to avoid a slow synchronous
            # scan running automatically.
            # ──────────────────────────────────────────────────────────────────────
            govulncheck

            # gore # Go REPL —  Nice-to-have for exploratory snippets/work.
            # iferr, fillstruct, goreleaser
          ]
          ++ cfg.extraTools;
      };
}
