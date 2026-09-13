# ──────────────────────────────────────────────────────────────────────────────
# src/dev/languages/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  imports = [
    ./options.nix
    ./defaults.nix
    ./go_hm.nix
    ./bash.nix
    ./c_cpp.nix
    ./d2.nix
    ./dart.nix
    ./js_js.nix
    ./kotlin.nix
    ./lua.nix
    ./nix.nix
    ./python.nix
    ./rust.nix
    ./zig.nix
  ];
}
