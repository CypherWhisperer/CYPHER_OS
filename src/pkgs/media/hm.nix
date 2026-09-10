# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/media/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
}:
let
  cfg = config.cypher-os.pkgs.media;
in
{
  imports = [
    ./options.nix
    ./clapper.nix
    ./spotify.nix
    ./vlc.nix
  ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.media.enable = lib.mkDefault (cypherOsProfile == "desktop");

    cypher-os.pkgs.media.vlc.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.media.clapper.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.media.spotify.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.media.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.vlc.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.media.vlc.enable requires cypher-os.pkgs.media.enable.
        '';
      }
      {
        assertion = cfg.clapper.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.media.clapper.enable requires cypher-os.pkgs.media.enable.
        '';
      }
      {
        assertion = cfg.spotify.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.media.spotify.enable requires cypher-os.pkgs.media.enable.
        '';
      }
    ];
  };
}
