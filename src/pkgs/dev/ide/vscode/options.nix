# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/vscode/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
   ...
}:
{
  options.cypher-os.pkgs.dev.ide.gui.vscode = {
    enable = lib.mkEnableOption "CypherOS VSCode IDE configuration";

    extensions = {
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: ONE PER {lang,devops,...} LEAF
      # ────────────────────────────────────────────────────────────────────────
      # Each leaf's default mirrors the external dependency but stays
      # independently overridable
      # ────────────────────────────────────────────────────────────────────────
      lang = {
        d2.enable = lib.mkEnableOption "D2 support in VSCode";
        go.enable = lib.mkEnableOption "Go support in VSCode";
        lua.enable = lib.mkEnableOption "Lua support in VSCode";
        nix.enable = lib.mkEnableOption "nix support in VSCode";
        php.enable = lib.mkEnableOption "PHP support in VSCode";
        sql.enable = lib.mkEnableOption "SQL support in VSCode";
        dart.enable = lib.mkEnableOption "Dart support in VSCode";
        rust.enable = lib.mkEnableOption "Rust support in VSCode";
        cCpp.enable = lib.mkEnableOption "C/C++ support in VSCode";
        jsTs.enable = lib.mkEnableOption "JS/TS support in VSCode";
        asm.enable = lib.mkEnableOption "Assembly support in VSCode";
        kotlin.enable = lib.mkEnableOption "Kotlin support in VSCode";
        python.enable = lib.mkEnableOption "Python support in VSCode";
        arduino.enable = lib.mkEnableOption "Arduino support in VSCode";
      };

      devops = {
        docker.enable = lib.mkEnableOption "Docker support in VSCOde";
        k8s.enable = lib.mkEnableOption "Kubernetes support in VSCOde";
        core.enable = lib.mkEnableOption "Core DevOps software stack support in VSCOde";
      };

      # ────────────────────────────────────────────────────────────────────────
      # NOTE: baseline category is not gated
      # ────────────────────────────────────────────────────────────────────────
    };

    # ──────────────────────────────────────────────────────────────────────────
    # Internal accumulator — not meant for user override. Each extension leaf
    # (i.e., from ./extensions/{lang,devops,baseline}) contributes its slice via
    # config.cypher-os.pkgs.dev.ide.vscode._sharedSettings.<key>.
    #
    # ./core_config.nix reads the final merged result exactly once, at the one
    # place userSettings and the fork-deployment files are written.
    # ──────────────────────────────────────────────────────────────────────────
    _sharedSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Internal: accumulated shared editor settings across VSCode-fork leaves. Do not set directly outside a leaf's own contribution.";
    };
  };
}
