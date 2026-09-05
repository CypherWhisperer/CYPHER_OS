# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;
in
{
  imports = [
    ./options.nix
    ./btop.nix
    ./htop.nix
    ./tmux.nix
    ./zellij.nix
    ./fastfetch.nix
  ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.core.enable) {

      # ────────────────────────────────────────────────────────────────────────
      # CLI Packages are eligible for both Server and Desktop Profiles
      # ────────────────────────────────────────────────────────────────────────
      home.packages = with pkgs; [
        fzf # fuzzy finder — pipes, history search, file selection
        ripgrep # rg: fast grep replacement, respects .gitignore
        bat # cat with syntax highlighting and line numbers
        fd # find replacement: simpler syntax, faster
        tree # directory tree display
        ranger # vim-keyed terminal file manager

        curl
        wget
        pass # password-store: GPG-backed password manager
        rsync
        keychain # SSH/GPG key agent manager across sessions
        lf
        yazi

        # ──────────────────────────────────────────────────────────────────────
        # YAZI PLUGINS
        # ──────────────────────────────────────────────────────────────────────
        # yaziPlugins.{
        #  mediainfo, time-travel, git, gitui, lazygit, vcs-files, starship,
        #  no-status, mediainfo, bookmarks, smartpaste, full-border,
        #  wl-clipboard, yatline-catppuccin, relative-motions, rich-preview,
        #  recycle-bin, smart-enter, toggle-pane, sudo, rsync, chmod, ouch,lsar,
        #  compress
        # }
        # ──────────────────────────────────────────────────────────────────────
      ];
    })

    # ──────────────────────────────────────────────────────────────────────────
    # CONFIGURATION DEFAULTS
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: pick ONE shape for the category's own top-level enable, don't leave
    # both:
    #
    #   Both-profile category:
    #     cypher-os. ... .enable = lib.mkDefault true; # i.e., no profile gating
    #
    #   Desktop-only category:
    #     cypher-os. ... .enable = lib.mkDefault (cypherOsProfile == "desktop");
    #     — pair with the matching assertion below.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.cli.core.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.btop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.htop.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.tmux.enable = lib.mkDefault cfg.enable;
      cypher-os.pkgs.cli.fastfetch.enable = lib.mkDefault cfg.enable;
    }

    {
      assertions = [
        {
          assertion = cfg.core.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.core.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.btop.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.btop.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.htop.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.htop.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.tmux.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.tmux.enable requires cypher-os.pkgs.cli.enable.
          '';
        }

        {
          assertion = cfg.fastfetch.enable -> cfg.enable;
          message = ''
            cypher-os.pkgs.cli.fastfetch.enable requires cypher-os.pkgs.cli.enable.
          '';
        }
      ];
    }
  ];
}
