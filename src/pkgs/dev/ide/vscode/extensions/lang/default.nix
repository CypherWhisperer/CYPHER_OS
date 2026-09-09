# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vscode/extensions/lang/default.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
let
  #cfgLang = config.cypher-os.pkgs.dev.language;
in
{
  imports = [
    ../../options.nix
    ./arduino.nix
    ./asm.nix
    ./c_cpp.nix
    ./d2.nix
    ./dart.nix
    ./go.nix
    ./js_ts.nix
    ./kotlin.nix
    ./lua.nix
    ./nix.nix
    ./php.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # RFC: EVALUATE GATING VSCODE LANGUAGE SUPPORT ON CYPHEROS LANGUAGE SUPPORT.
  # ────────────────────────────────────────────────────────────────────────────
  #config = {
  #  cypher-os.pkgs.dev.ide.vscode.extensions.lang.rust.enable = lib.mkDefault cfgLang.rust.enable;
  #};
}

