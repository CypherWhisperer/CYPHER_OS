# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/tmux.nix
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
#   - All tmux settings and keybindings
#   - Plugin declarations (managed by Nix — TPM is fully replaced)
#   - Catppuccin Mocha theme configuration
#   - Status bar layout (app + cpu + session + uptime + battery)
#
# ──────────────────────────────────────────────────────────────────────────────
# NO TPM:
#   TPM (tmux plugin manager) is replaced by Home Manager's plugin system.
#   Nix fetches and builds all plugins declaratively. You never need to run
#   <prefix> I again. The `run '~/.tmux/plugins/tpm/tpm'` line in conventional
#   tmux configurations under `~/.tmux/tmux.conf` is not present
#   (neither needed) here — it would break things if added.
#
# ──────────────────────────────────────────────────────────────────────────────
# Plugins not in nixpkgs (tmux-sessionx, tmux-browser, tmux-cargo) are
# fetched from GitHub using pkgs.tmuxPlugins.mkTmuxPlugin. They are pinned
# by hash — run `nix-prefetch-url --unpack <tarball-url>` to update a pin.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;

  # ── Custom Plugin Declarations ─────────────────────────────────────────────
  # These three plugins are not in nixpkgs.tmuxPlugins so we fetch them
  # directly from GitHub. The hash pins the exact commit — update it when
  # you want a newer version by running:
  #  nix-prefetch-url --unpack https://github.com/user/repo/archive/<rev>.tar.gz
  # ──────────────────────────────────────────────────────────────────────────────
  tmux-sessionx = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-sessionx";
    version = "unstable-2024-01-01";
    src = pkgs.fetchFromGitHub {
      owner = "omerxx";
      repo = "tmux-sessionx";
      rev = "301ce314c9bd25b803667e00c50a4f57d4b33aa2";
      sha256 = "1byzwj65r52mfvpf549b0rgnkn6252hzg37avfyhk24mnmivbrr2";
    };
  };

  primaryShell = cypherOsConstants.primaryUserShell;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.tmux.enable) {
    programs.tmux = {
      enable = true;

      # ── Core Settings ─────────────────────────────────────────────────────────
      prefix = "C-s";
      baseIndex = 1; # windows start at 1, not 0
      mouse = true;
      keyMode = "vi"; # vi copy mode
      historyLimit = 50000;
      escapeTime = 0; # no delay after Esc (critical for vim inside tmux)

      # ── Terminal ────────────────────────────────────────────────────────────
      # terminal: tells tmux what capabilities to advertise to programs inside
      # it. tmux-256color is the right value — it enables 256-color and
      # italic support.
      #
      # The overrides below add true color (RGB) so colours inside tmux match
      # what's seen in kitty/ghostty directly.
      # ────────────────────────────────────────────────────────────────────────
      terminal = "tmux-256color";

      # ── Shell ───────────────────────────────────────────────────────────────
      # Explicit shell path ensures tmux always uses the configured Nix-managed
      # primary user's primary shell, not whatever /etc/shells resolves first
      # on a non-NixOS host.
      # ────────────────────────────────────────────────────────────────────────
      shell = "${pkgs.${primaryShell}}/bin/${primaryShell}";

      # ── Plugin Declarations ─────────────────────────────────────────────────
      # Home Manager installs these via Nix — no TPM, no `<prefix> I` needed.
      # Order matters for plugins that depend on each other: sensible first,
      # theme before status bar plugins that extend it, TPM-style init
      # plugins last.
      # ────────────────────────────────────────────────────────────────────────
      plugins = with pkgs.tmuxPlugins; [
        sensible # sane defaults (overrides some of the above cleanly)
        yank # system clipboard integration with 'y' in copy mode
        vim-tmux-navigator # Ctrl-h/j/k/l to move between vim splits and tmux panes
        cpu

        # ──────────────────────────────────────────────────────────────────────
        # Session persistence
        # ──────────────────────────────────────────────────────────────────────
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents "on"
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore "on"
            set -g @continuum-save-interval "15"
          '';
        }

        # ──────────────────────────────────────────────────────────────────────
        # Status bar utilities
        # ──────────────────────────────────────────────────────────────────────
        battery
        online-status

        # ──────────────────────────────────────────────────────────────────────
        # Catppuccin theme — must come before status bar configuration
        # so the theme variables (@thm_*) are defined when status-right is built
        # ──────────────────────────────────────────────────────────────────────
        {
          plugin = catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavor "mocha"
            set -g @catppuccin_window_status_style "rounded"
          '';
        }

        # ──────────────────────────────────────────────────────────────────────
        # Custom plugins (fetched from GitHub above)
        # ──────────────────────────────────────────────────────────────────────
        {
          plugin = tmux-sessionx;
          extraConfig = ''
            set -g @sessionx-bind "o"
          '';
        }
      ];

      # ── extraConfig ─────────────────────────────────────────────────────────
      # Settings that don't have a dedicated Home Manager option go here.
      # This is appended to the generated tmux.conf after plugin declarations.
      # ────────────────────────────────────────────────────────────────────────
      extraConfig = ''
        # ── True Color Support ─────────────────────────────────────────────────
        # These overrides tell tmux to pass RGB color escape sequences through to
        # the terminal. Without them, colors inside tmux look washed out compared
        # to outside tmux, especially with Tokyo Night / Catppuccin palettes.
        set -ag terminal-overrides ",xterm-256color:RGB"
        set-option -sa terminal-overrides ",xterm*:Tc"
        set -gq allow-passthrough on   # kitty image protocol passthrough

        # ── Status Bar ─────────────────────────────────────────────────────────
        set-option -g status-position top

        set -g status-right-length 100
        set -g status-left-length  100
        set -g status-left  ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag  status-right "#{E:@catppuccin_status_session}"
        set -ag  status-right "#{E:@catppuccin_status_uptime}"
        set -agF status-right "#{E:@catppuccin_status_battery}"

        # ── Window & Pane Numbering ─────────────────────────────────────────────
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on    # close window 2 of 1,2,3 → windows renumber to 1,2

        # ── Keybindings ────────────────────────────────────────────────────────

        # Reload config — <prefix> r
        unbind r
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

        # Split panes in current working directory
        # '-' → vertical split (new pane below), '|' → horizontal split (new pane right)
        unbind '"'
        unbind %
        bind - split-window -v -c "#{pane_current_path}"
        bind | split-window -h -c "#{pane_current_path}"

        # Pane navigation — vim keys with prefix
        # (vim-tmux-navigator handles Ctrl-h/j/k/l without prefix for seamless vim↔tmux)
        bind-key h select-pane -L
        bind-key j select-pane -D
        bind-key k select-pane -U
        bind-key l select-pane -R

        # Window navigation — Alt+Shift+h/l (no prefix needed)
        bind -n M-H previous-window
        bind -n M-L next-window

        # Pane resize — repeatable with -r flag, vim directions
        bind -r h resize-pane -L 5
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5

        # Pane maximize — toggle zoom
        bind -r m resize-pane -Z

        # New named session with prompt
        bind-key n command-prompt "new-session -s '%%'"

        # ── Copy Mode ──────────────────────────────────────────────────────────
        # <prefix> v → enter copy mode
        # v          → begin selection (in copy mode)
        # C-v        → toggle rectangle/line selection
        # y          → copy selection and exit copy mode
        # Mouse drag selects but does NOT exit copy mode
        unbind v
        bind v copy-mode

        bind-key -T copy-mode-vi 'v'   send-keys -X begin-selection
        bind-key -T copy-mode-vi 'C-v' send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi 'y'   send-keys -X copy-selection-and-cancel

        # Prevent mouse drag from exiting copy mode
        unbind -T copy-mode-vi MouseDragEnd1Pane
      '';
    };
  };
}
