# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/languages/c_cpp.nix
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

  config = lib.mkIf (cfg.enable && cfg.cCpp.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # libgcc: GCC runtime libraries. Needed for linking compiled binaries and
      # running programs that depend on GCC's runtime (libgcc_s, libstdc++).
      # Most native compilation on Linux depends on this being present.
      # ────────────────────────────────────────────────────────────────────────
      libgcc

      cmake
      gcc
      vcpkg # C++ Library Manager for Windows, Linux, and macOS
    ];
  };
}
