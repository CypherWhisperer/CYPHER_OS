# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/zig.nix
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

  config = lib.mkIf (cfg.enable && cfg.zig.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # zig: Zig language compiler and build system. Low-level systems language
      # with manual memory management and C interop. Also functions as a C/C++
      # cross-compiler (zig cc). Increasingly used as a C toolchain replacement.
      # Usage: zig version   zig build   zig cc (as a C compiler)
      # ────────────────────────────────────────────────────────────────────────
      zig
    ];
  };
}
