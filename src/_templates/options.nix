# ──────────────────────────────────────────────────────────────────────────────
# src/ ... /options.nix
# ──────────────────────────────────────────────────────────────────────────────

{ lib, ... }:

{
  options.cypher-os. ... = {
    enable = lib.mkEnableOption " ";

    # ──────────────────────────────────────────────────────────────────────────
    # Doesn't currently have GUI packages and/or span desktop and server
    # profiles, hence no <category>.gui.* pattern
    # ──────────────────────────────────────────────────────────────────────────

    # OR

    #gui = {
    #  enable = lib.mkEnableOption "GUI (Graphical User Interface) Packages suite.";
    #}
  }
}
