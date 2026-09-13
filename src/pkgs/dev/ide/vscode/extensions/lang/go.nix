# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/go.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide.gui.vscode;
  #vscMkt = pkgs.nix-vscode-extensions.vscode-marketplace;
  #openVsx = pkgs.nix-vscode-extensions.open-vsx;
in
{
  imports = [ ../../options.nix ];

  config = lib.mkIf (cfg.enable && cfg.extensions.lang.go.enable) {
    programs.vscode.extensions =
      with pkgs.vscode-extensions;
      [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 1: extensions available as pkgs.vscode-extensions.*
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # NOTE:
        # ──────────────────────────────────────────────────────────────────────
        # golang-go extension itself does NOT need gopls/dlv/golangci-lint
        # declared separately here: it finds them on PATH, and
        # cypher-os...languages.go (go-hm.nix file) already puts gopls,
        # delve, golangci-lint, gofumpt, gotools, gomodifytags, gotests,
        # impl, and govulncheck on PATH via home.packages.
        # ──────────────────────────────────────────────────────────────────────
        golang.go
      ]
      ++ [
        # ──────────────────────────────────────────────────────────────────────
        # Tier 2: nix-vscode-extensions (marketplace/open-vsx).
        # ──────────────────────────────────────────────────────────────────────
      ];

    # ──────────────────────────────────────────────────────────────────────────
    # userSettings: written to VSCode's settings.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.dev.ide.gui.vscode._sharedSettings = {
      # ────────────────────────────────────────────────────────────────────────
      # GO
      # ────────────────────────────────────────────────────────────────────────
      # ══════════════════════════════════════════════════════════════════════
      # LANGUAGE SERVER
      # ══════════════════════════════════════════════════════════════════════
      # ───────────────────────────────────────────────────────────────────────
      # Extension-level tool version management is OFF (go.toolsManagement.
      # autoUpdate = false): tool versions are Nix's job (cypher-os...languages.
      # go.extraTools / go-hm.nix), not the extension's.
      # ───────────────────────────────────────────────────────────────────────
      "go.useLanguageServer" = true;
      "go.toolsManagement.autoUpdate" = false;
      "go.toolsManagement.checkForUpdates" = "local"; # or "proxy" / "off"

      # NOTE: go.gopath / go.goroot deliberately omitted. programs.go already
      # sets GOPATH and puts the chosen toolchain on PATH — the extension
      # auto-discovers both from there. Setting them here to "" is a no-op
      # that reads like an intentional override when it isn't; omitting them
      # entirely says the same thing more honestly.

      # NOTE: go.toolsEnvVars deliberately omitted. Any GOPROXY/GOSUMDB/etc.
      # override belongs in cypher-os...languages.go.extraEnv (Nix), not here —
      # that way the terminal `go` and VSCode's `go` agree by construction
      # instead of by two configs happening to match.

      # ══════════════════════════════════════════════════════════════════════
      # FORMATTING
      # ══════════════════════════════════════════════════════════════════════
      # Delegate to gopls (gofumpt = true, below) rather than a separate
      # formatter process — one formatting code path, not two that can disagree.
      #
      # gofumpt is enabled *through* gopls rather than via go.formatTool, so
      # there's one formatting code path instead of two that can disagree.
      #
      # Alternatives: "gofumpt", "goimports", "gofmt", "custom"
      # ──────────────────────────────────────────────────────────────────────
      "go.formatTool" = "default";
      # "go.alternateTools" = {
      #   "gofumpt" = "${pkgs.gofumpt}/bin/gofumpt";
      # };

      # ══════════════════════════════════════════════════════════════════════
      # LINTING
      # ══════════════════════════════════════════════════════════════════════
      # go.lintTool (commented out): gopls's embedded staticcheck (below)
      # already covers live in-editor linting. golangci-lint is still installed
      # (go-hm.nix) for CI-parity terminal runs / `golangci-lint fmt`.
      #
      # go.lintFlags is commented out alongside it on purpose — flags for a
      # disabled tool is bug (config that looks live but has nothing to apply to).
      #
      # NOTE ON --fast: --fast is v1-era; v2 dropped it — re-derive flags from
      # .golangci.yml if it ever gets uncommented.
      # ───────────────────────────────────────────────────────────────────────
      # "go.lintTool" = "golangci-lint-v2";
      # "go.lintFlags" = [ "--fast" ];
      # ──────────────────────────────────────────────────────────────────────

      "go.lintOnSave" = "package"; # "workspace" | "off"
      "go.vetOnSave" = "package";

      # ══════════════════════════════════════════════════════════════════════
      # TESTING
      # ══════════════════════════════════════════════════════════════════════
      "go.testOnSave" = false; # noisy with autosave enabled elsewhere in the profile
      "go.coverOnSave" = false;
      "go.coverOnSingleTest" = true;
      "go.testTimeout" = "30s";

      "go.testExplorer.enable" = true;
      "go.testExplorer.packageDisplayMode" = "nested";
      "go.testExplorer.showOutput" = true;

      # ──────────────────────────────────────────────────────────────────────
      # -race dropped from the default flags. Race detection instruments every
      # goroutine/memory access, which measurably slows test runs and raises
      # memory use — worth paying for deliberately (a `-race` CI job, or a
      # manual `go test -race ./...` when touching concurrent code) rather than
      # on every save.
      #
      # Re-add "-race" if this default should instead catch data races
      # continuously during normal test-on-save/Test Explorer runs —  the tradeoff
      # is strictly slower everyday feedback in exchange for racing bugs surfacing
      # immediately instead of only in CI.
      # ──────────────────────────────────────────────────────────────────────
      "go.testFlags" = [ "-v" ];

      # "go.testEnvVars" = {
      #   "GO111MODULE" = "on";
      # };

      # ──────────────────────────────────────────────────────────────────────
      # Paired deliberately with gopls.codelenses.test = false
      # below: use the extension's own client-side test UI, suppress gopls's
      # redundant LSP-level test codelens, so there's exactly one "run test"
      # affordance instead of two competing ones.
      # ──────────────────────────────────────────────────────────────────────
      "go.enableCodeLens" = {
        "runtest" = true;
      };

      # ══════════════════════════════════════════════════════════════════════
      # DEBUGGING
      # ══════════════════════════════════════════════════════════════════════
      # dlv-dap is the current (non-legacy) debug adapter.
      # ──────────────────────────────────────────────────────────────────────
      "go.delveConfig" = {
        debugAdapter = "dlv-dap";
        showGlobalVariables = false;
        hideSystemGoroutines = true;
      };

      # ══════════════════════════════════════════════════════════════════════
      # BUILD
      # ══════════════════════════════════════════════════════════════════════
      # "go.buildOnSave" = "off";
      # "go.buildTags" = "";
      # "go.buildFlags" = [ ];

      # ══════════════════════════════════════════════════════════════════════
      # EDITOR INTEGRATION — save pipeline, per-filetype
      # ══════════════════════════════════════════════════════════════════════
      "[go]" = {
        "editor.formatOnSave" = true;
        "editor.defaultFormatter" = "golang.go";
        "editor.suggest.snippetsPreventQuickSuggestions" = false;
        "editor.semanticHighlighting.enabled" = true;
        "editor.inlayHints.enabled" = "onUnlessPressed";

        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
      };

      # ───────────────────────────────────────────────────────────────────────
      # "[go.mod]" / "[go.work]": live candidates for the same treatment
      # as [go] if either file type starts getting hand-edited often enough to
      # want format-on-save.
      # ───────────────────────────────────────────────────────────────────────
      # "[go.mod]" = {
      #   "editor.defaultFormatter" = "golang.go";
      #   "editor.formatOnSave" = true;
      #   "editor.codeActionsOnSave" = {
      #     "source.organizeImports" = "explicit";
      #   };
      # };
      # "[go.work]" = {
      #   "editor.defaultFormatter" = "golang.go";
      #   "editor.formatOnSave" = true;
      # };

      # ══════════════════════════════════════════════════════════════════════
      # LANGUAGE SERVER — gopls
      # ──────────────────────────────────────────────────────────────────────
      # NOTE ON SCOPE: everything under this top-level "gopls" key is NOT
      # an extension setting — it's read directly by the gopls binary via LSP
      # initialization options. The extension is a thin passthrough for that
      # block. This distinction matters for the Neovim configuration: the same
      # `gopls` attrset (minus the VSCode-extension-only `go.*` keys)
      # is exactly what gets handed to `vim.lsp.config('gopls', { settings = {
      # gopls = { ... } } })` — one gopls config, two editors.
      # ───────────────────────────────────────────────────────────────────────
      # KEY-FORM POLICY: gopls documents most settings under hierarchical
      # headings (ui.diagnostic.*, ui.completion.*, formatting.*, build.*) for
      # readability, but its confirmed, stable JSON keys are the flat, un-prefixed
      # names (`hints`, `analyses`, `staticcheck`, `gofumpt`, `local`,
      # `completeUnimported`, `directoryFilters`, ...).
      # ══════════════════════════════════════════════════════════════════════
      "gopls" = {
        # ── Completion ──────────────────────────────────────────────────────
        "usePlaceholders" = true;
        "completeUnimported" = true;
        "completeFunctionCalls" = true;

        # ── Navigation ──────────────────────────────────────────────────────
        "importShortcut" = "Both";
        "symbolScope" = "workspace";
        "symbolMatcher" = "fuzzy";

        # ── Formatting ──────────────────────────────────────────────────────
        "gofumpt" = true; # stricter-than-gofmt formatting, applied via gopls

        # ASSUMPTION: github username.
        # ──────────────────────────────────────────────────────────────────────
        # "github.com/CypherWhisperer"; # import grouping for thy own modules
        # ──────────────────────────────────────────────────────────────────────
        "local" = "";

        # ── Diagnostics ─────────────────────────────────────────────────────
        "staticcheck" = true; # embed the full staticcheck suite
        "vulncheck" = "Imports";
        "analyses" = {
          "unusedparams" = true;
          "shadow" = true;
          "unreachable" = true;
          "nilness" = true;
          "useany" = true;
          "unusedwrite" = true;
          "fieldalignment" = false;
        };

        # ── Inlay hints ─────────────────────────────────────────────────────
        # Curated set, chosen by "catches a real bug class" vs. "restates the
        # obvious": ignoredError/parameterNames/constantValues/
        # functionTypeParameters on; the four composite-literal/assign/range
        # hints off, since those fire on nearly every line of idiomatic Go
        # (struct literals, `:=`, range loops) and drown out the useful ones.
        # ────────────────────────────────────────────────────────────────────
        "hints" = {
          "constantValues" = true;
          "ignoredError" = true;
          "functionTypeParameters" = true;
          "parameterNames" = true;
          "assignVariableTypes" = false;
          "compositeLiteralFields" = false;
          "compositeLiteralTypes" = false;
          "rangeVariableTypes" = false;
        };

        # ── Semantic highlighting ───────────────────────────────────────────
        "semanticTokens" = true;

        # ── Codelenses ──────────────────────────────────────────────────────
        # checkout: https://go.dev/gopls/settings#codelenses-mapenumbool
        # ────────────────────────────────────────────────────────────────────
        "codelenses" = {
          "test" = false; # extension has its own client-side test UI (go.enableCodeLens.runtest, above)
          "generate" = true;
          "regenerate_cgo" = true;
          "tidy" = true;
          "upgrade_dependency" = true;
          "vulncheck" = false; # run govulncheck from the terminal / CI instead
          "gc_details" = false;
          "vendor" = true;
        };

        # ── Build ───────────────────────────────────────────────────────────
        "directoryFilters" = [
          "-**/node_modules"
          "-**/vendor"
          "-**/.git"
        ];

        # "buildFlags" = [ ];
      };
    };
  };
}
