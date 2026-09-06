# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/core/hm.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.core;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # ────────────────────────────────────────────────────────────────────────
      # CLI/TUI Packages are eligible for both Server and Desktop Profiles
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
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.pkgs.core.enable = lib.mkDefault true;
    }
  ];
}
