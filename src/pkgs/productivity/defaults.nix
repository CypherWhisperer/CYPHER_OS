# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/productivity/defaults.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  cypherOsConstants,
}:
let
  cfg = config.cypher-os.pkgs.productivity;
  # ────────────────────────────────────────────────────────────────────────────
  # NOTE: MOVE THIS WHEN MOVING THE OBSIDIAN ASSERTION BELOW:
  # ────────────────────────────────────────────────────────────────────────────
  homePrefix = "${cypherOsConstants.homeDirectory}/";
in
{
  imports = [ ./options.nix ];

  config = {
    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    cypher-os.pkgs.productivity.enable = lib.mkDefault (cypherOsProfile == "desktop");

    cypher-os.pkgs.productivity.obs.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.claude.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.zathura.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.logseq.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.affine.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.libreOffice.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.obsidian.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.drawio.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.staruml.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.anydesk.enable = lib.mkDefault cfg.enable;
    cypher-os.pkgs.productivity.rustdesk.enable = lib.mkDefault cfg.enable;

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    assertions = [
      {
        assertion = cfg.enable -> cypherOsProfile == "desktop";
        message = ''
          cypher-os.pkgs.productivity.enable requires cypher-os.profile.active == "desktop".
        '';
      }

      {
        assertion = cfg.obs.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.obs.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.claude.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.claude.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.zathura.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.zathura.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.logseq.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.logseq.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.affine.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.affine.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.libreOffice.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.libreOffice.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.obsidian.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.obsidian.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      # ────────────────────────────────────────────────────────────────────────
      # NOTE: MOVE THIS ASSERTION UNDER ./obsidian/ ONCE ITS MODULARIZATION IS
      # IN PLACE
      # ────────────────────────────────────────────────────────────────────────
      {
        # ──────────────────────────────────────────────────────────────────────
        # removePrefix returns its input UNCHANGED, not an error, if
        # obsidianVaultRoot doesn't start with homeDirectory — this assertion
        # converts that silent failure into a loud one. It is EXPECTED to start
        # failing once the planned @data mount session moves obsidianVaultRoot
        # outside homeDirectory — that failure is the intended trigger for the
        # symlink below, not a bug to patch around when it happens.
        # ──────────────────────────────────────────────────────────────────────
        assertion = lib.hasPrefix homePrefix cypherOsConstants.obsidianVaultRoot;
        message = ''
          cypher-os.constants.obsidianVaultRoot ("${cypherOsConstants.obsidianVaultRoot}") is no
          longer nested under homeDirectory ("${cypherOsConstants.homeDirectory}") —
          programs.obsidian.vaults.my-obsidian-notes.target only accepts a $HOME-relative path.
          See the BTRFS configuration RFC for the symlink-based fix.
        '';
      }

      {
        assertion = cfg.drawio.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.drawio.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.staruml.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.staruml.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.anydesk.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.anydesk.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
      {
        assertion = cfg.rustdesk.enable -> cfg.enable;
        message = ''
          cypher-os.pkgs.productivity.rustdesk.enable requires cypher-os.pkgs.productivity.enable.
        '';
      }
    ];
  };
}
