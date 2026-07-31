# modules/shell/zsh.nix
#
# Home Manager module for Zsh shell configuration.
#
# WHAT THIS FILE OWNS:
#   - Zsh installation and core options (history, completion, keybinds)
#   - Oh-My-Zsh framework (plugins only — no theme, p10k handles that)
#   - Powerlevel10k prompt (deployed via home.file, sourced in initExtra)
#   - fzf integration (Ctrl-R, Ctrl-T, Alt-C via programs.fzf)
#   - All aliases (navigation, git, dev, system conveniences)
#   - Custom functions (fuzzy helpers, command_not_found_handler, do_render)
#   - keychain SSH agent integration
#   - NVM (Node Version Manager) sourcing
#   - fastfetch auto-launch on interactive terminal open
#   - XDG compliance: history, compdump, and cache under XDG paths
#
# WHAT THIS FILE DOES NOT OWN:
#   - The fzf *package* itself — declared in modules/common/cli.nix
#   - The keychain *package*  — declared in modules/common/cli.nix
#   - The fastfetch *package* — declared in modules/common/cli.nix
#   - Font packages            — declared in modules/de/gnome.nix
#
# ZDOTDIR NOTE:
#   programs.zsh in Home Manager sets ZDOTDIR to $HOME/.config/zsh by default
#   (via /etc/zshenv on NixOS, or ~/.zshenv on other distros).
#   Under XDG profile separation, XDG_CONFIG_HOME is overridden per DE session
#   before the shell starts, so ZDOTDIR resolves correctly per profile automatically.
#   No manual ZDOTDIR wiring is needed here.

{
  config,
  pkgs,
  lib,
  self,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.shell.enable && config.cypher-os.shell.zsh.enable) {

    home.packages = with pkgs; [
      ## ────────────── ZSH ──────────────────────────────
      pkgs.zsh-powerlevel10k # the p10k theme itself
      pkgs.keychain # SSH agent manager
      pkgs.eza # modern ls replacement (used in aliases)
      # Once hooked into your shell direnv is looking for an .envrc file in your
      # current directory before every prompt. If found it will load the exported
      # environment variables from that bash script into your current environment,
      # and unload them if the .envrc is not reachable from the current path anymore.
      # In short, this little tool allows you to have project-specific environment
      # variables.
      direnv
    ];
    # ─────────────────────────────────────────────────────────────────────────────
    # ZSH CORE
    # ─────────────────────────────────────────────────────────────────────────────
    programs.zsh = {
      enable = true;

      # dotDir: where HM places .zshrc, .zshenv, .zprofile.
      # Relative to $HOME. Results in ~/.config/zsh/.zshrc etc.
      # Combined with ZDOTDIR=$HOME/.config/zsh, this keeps $HOME clean.
      dotDir = "${config.xdg.configHome}/zsh";

      # ── History ───────────────────────────────────────────────────────────────
      # historyFile: explicit path keeps history on @home regardless of which
      # OS is booted. The file is in ZDOTDIR so it moves with the XDG profile.
      history = {
        path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
        size = 50000; # lines kept in memory during session
        save = 50000; # lines written to file
        share = true; # share history across all zsh sessions (SHARE_HISTORY)
        extended = true; # save timestamps with each entry (EXTENDED_HISTORY)
        ignoreDups = true; # don't record duplicate consecutive entries
        ignoreSpace = true; # don't record entries starting with a space
        expireDuplicatesFirst = true; # expire dupes before unique entries when trimming
      };

      # ── Completion ────────────────────────────────────────────────────────────
      # enableCompletion: generates the completions and wires up compinit.
      # autosuggestion and syntaxHighlighting are OMZ plugins here, but HM also
      # has first-class support — using OMZ for consistency with your existing setup.
      enableCompletion = true;
      autosuggestion.enable = true; # zsh-autosuggestions (inline ghost text)
      syntaxHighlighting.enable = true; # zsh-syntax-highlighting (color as you type)

      # ── Oh-My-Zsh ─────────────────────────────────────────────────────────────
      # theme = "": blank — p10k manages the prompt, OMZ theme system is bypassed.
      # Powerlevel10k must NOT be set as an OMZ theme here; it's sourced manually
      # in initExtraBeforeCompInit to enable instant prompt correctly.
      oh-my-zsh = {
        enable = true;
        theme = ""; # p10k takes over — no OMZ theme
        plugins = [
          "git" # git aliases (gst, gco, gp, gl, etc.)
          "sudo" # press Esc twice to prepend sudo to last command
          "colored-man-pages" # syntax-coloured man pages
          "command-not-found" # suggests packages for unknown commands (distro-aware)
          "direnv" # hooks direnv into the shell
          "fzf" # OMZ fzf plugin: key bindings + completion
        ];
      };

      # ── initExtraBeforeCompInit ───────────────────────────────────────────────
      # Code that must run BEFORE compinit. Powerlevel10k instant prompt belongs
      # here — it caches the prompt before the slow parts of zshrc execute.
      # Instant prompt requires this block to be at the very top of zshrc execution.
      initContent = lib.mkMerge [

        (lib.mkOrder 500 ''
          # ── Completion Security Bypass ─────────────────────────────────────────
            # compinit rejects Nix store paths as "insecure" because they're not owned
          # by root or $USER. The -u flag suppresses the interactive prompt and the
          # insecure directory warning. Safe on NixOS — the store is immutable.
          ZSH_DISABLE_COMPFIX=true
        '')

        (lib.mkOrder 550 ''
          # ── Powerlevel10k: Instant Prompt ──────────────────────────────────────
          # Must run before anything that produces output or requires console input.
          # quiet mode: suppress warnings about console output during init.
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')

        ''
          function _tree_wrapper() {
            # if any arguments are passed, delegate to command tree; otherwise use eza
            if (( $# > 0 )); then
              command tree "$@"
            else
              eza --tree --icons
            fi
          }
        ''

        # ── initExtra ─────────────────────────────────────────────────────────────
        # Everything else: environment variables, functions, keybinds, tool inits.
        # OMZ has already been sourced by this point (HM sources it before initExtra).

        ''
          # ── Powerlevel10k: Load Theme ───────────────────────────────────────────
          # Source the p10k theme from the Nix store (installed via home.packages).
          # Then source the p10k config file deployed by home.file below.
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ -f ''${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh ]] \
            && source ''${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh

          # ── ZSH Options ────────────────────────────────────────────────────────
          setopt AUTO_CD              # type a directory name to cd into it
          setopt AUTO_PUSHD           # cd pushes old dir onto stack (use popd to go back)
          setopt PUSHD_IGNORE_DUPS    # don't push duplicate dirs onto the stack
          setopt PUSHD_SILENT         # don't print the dir stack after pushd/popd
          setopt CORRECT              # suggest corrections for mistyped commands
          setopt COMPLETE_ALIASES     # complete aliases as commands

          # ── Completion Styling ─────────────────────────────────────────────────
          # Use the same menu-driven completion you had, with case-insensitive matching
          zstyle ':completion:*' menu select
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}  # coloured completion list
          zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
          # Keep compinit security check quiet on Nix store paths
          zstyle ':completion:*' accept-exact-dirs true

          # ── Key Bindings ───────────────────────────────────────────────────────
          bindkey '^[[H'  beginning-of-line   # Home key
          bindkey '^[[F'  end-of-line         # End key
          bindkey '^[[3~' delete-char         # Delete key
          bindkey '^[[A'  history-search-backward  # Up: history prefix search
          bindkey '^[[B'  history-search-forward   # Down: history prefix search

          # ── Environment Variables ──────────────────────────────────────────────
          #export EDITOR="nvim"
          export EDITOR="vim"
          export VISUAL="nvim"
          export PAGER="less"
          export LESS="-R --mouse"  # -R: keep ANSI colours; --mouse: scroll with mouse

          # XDG compliance for tools that don't respect it by default
          export LESSHISTFILE="''${XDG_STATE_HOME:-$HOME/.local/state}/less_history"
          export PYTHON_HISTORY="''${XDG_STATE_HOME:-$HOME/.local/state}/python_history"
          export PARALLEL_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}/parallel"
          export SCREENRC="''${XDG_CONFIG_HOME:-$HOME/.config}/screen/screenrc"
          export WGETRC="''${XDG_CONFIG_HOME:-$HOME/.config}/wgetrc"

          # ── PATH Extensions ────────────────────────────────────────────────────
          # ~/.local/bin: Home Manager places user scripts and launchers here
          export PATH="$HOME/.local/bin:$PATH"

          # ── NVM (Node Version Manager) ─────────────────────────────────────────
          # NVM is not in nixpkgs in a form that integrates cleanly with HM programs.nodejs.
          # We source it from its standard install location.
          # When you're ready to go fully declarative, replace this with:
          #   programs.nvm.enable = true;  (available in newer HM versions)
          # or switch to fnm (programs.fnm) which integrates better with Nix.
          export NVM_DIR="$HOME/.nvm"
          [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
          [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

          # ── Keychain (SSH Agent) ───────────────────────────────────────────────
          # Keychain manages the ssh-agent lifecycle. It starts the agent once per
          # login session and caches the socket path so all shells (and tmux panes)
          # share the same agent. --quiet suppresses the startup banner.
          # The key name here is the filename under ~/.ssh/ — no path, no extension.
          # Each key is checked for existence before invoking keychain so the shell
          # doesn't error on machines where a key hasn't been generated yet.

          # ATTEMPT FOR EXTENDING SUPPORT FOR MULTIPLE KEYS
          # To add a new identity: generate the key, add it to the relevant service,
          # then append the filename to the keychain invocation below.
          #local _keychain_keys=()
          #[[ -f "$HOME/.ssh/id_ed25519_cypher" ]]  && _keychain_keys+=(id_ed25519_cypher)
          #[[ -f "$HOME/.ssh/id_ed25519_pentara" ]] && _keychain_keys+=(id_ed25519_pentara)
          #if (( ''${#_keychain_keys[@]} > 0 )); then
          #  eval $(keychain --quiet --eval "''${_keychain_keys[@]}")
          #fi

          # ORIGINAL AND CURRENT IMPLEMENTATION - FOR A SINGLE KEY
          if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
            eval $(keychain --quiet --eval id_ed25519)
          fi

          # ── Custom Functions ───────────────────────────────────────────────────

          # do_render: detect whether the current terminal supports image rendering.
          # Used by the fastfetch block above and available for other scripts.
          # Extend TERMINAL_IMAGE_SUPPORT if you add a new image-capable terminal.
          function do_render {
            local type="''${1:-image}"
            local TERMINAL_IMAGE_SUPPORT=(kitty ghostty WezTerm konsole)
            local TERMINAL_NO_ART=(code codium cursor)
            local CURRENT_TERMINAL="''${TERM_PROGRAM:-$(ps -o comm= -p $(ps -o ppid= -p $$))}"
            case "''${type}" in
              image) [[ " ''${TERMINAL_IMAGE_SUPPORT[@]} " =~ " ''${CURRENT_TERMINAL} " ]] ;;
              art)   [[ ! " ''${TERMINAL_NO_ART[@]} "     =~ " ''${CURRENT_TERMINAL} " ]] ;;
              *) return 1 ;;
            esac
          }

          # command_not_found_handler: pretty error + package search hint.
          # On NixOS/Nix-enabled systems, suggests `nix-locate` or nixpkgs search.
          # On Arch/Debian/Fedora, the OMZ command-not-found plugin handles this.
          # This function is a fallback for when no package manager hook fires.
          function command_not_found_handler {
            # BUG:
            #   local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
            #
            # The escape sequences (\e[...]) are not being interpreted because printf
            # in zsh doesn't expand \e by default — it's a bash-ism. Zsh's printf only
            # expands standard C escapes (\n, \t, etc.), not \e.
            #
            # CORRECTED:
            local purple=$'\e[1;35m' bright=$'\e[0;1m' green=$'\e[1;32m' reset=$'\e[0m'

            #printf "''${green}zsh''${reset}: command ''${purple}NOT''${reset} found: ''${bright}%s ''${reset}\n" "$1"
            printf "%szsh%s: command %sNOT%s found: %s%s%s\n" \
              "$green" "$reset" \
              "$purple" "$reset" \
              "$bright" "$1" "$reset"
            # Hint toward nix-locate if available (useful on NixOS and Nix-on-Linux)
            if command -v nix-locate &>/dev/null; then
              #printf "''${bright}Try:''${reset} nix-locate bin/%s\n" "$1"
              printf "%sTry:%s nix-locate bin/%s\n" "$bright" "$reset" "$1"
            fi
            return 127
          }

          # ── fzf Custom Functions ───────────────────────────────────────────────
          # These extend fzf beyond the default Ctrl-R/Ctrl-T bindings.
          # All four are aliased below (ffcd, ffe, ffec, ffch).

          # ffcd: fuzzy cd — browse directory tree, cd on selection
          function _fuzzy_change_directory() {
            local initial_query="$1"
            local selected_dir
            local fzf_options=(
              '--preview=ls -p {}'
              '--preview-window=right:60%'
              '--height=80%'
              '--layout=reverse'
              '--cycle'
            )
            local max_depth=7
            [[ -n "$initial_query" ]] && fzf_options+=("--query=$initial_query")
            selected_dir=$(find . -maxdepth $max_depth \
              \( -name .git -o -name node_modules -o -name .venv \
                -o -name target -o -name .cache \) -prune \
              -o -type d -print 2>/dev/null | fzf "''${fzf_options[@]}")
            [[ -n "$selected_dir" && -d "$selected_dir" ]] && cd "$selected_dir"
          }

          # ffe: fuzzy edit — browse files, open selected in $EDITOR
          function _fuzzy_edit_search_file() {
            local initial_query="$1"
            local selected_file
            local fzf_options=(
              '--height=80%' '--layout=reverse'
              '--preview-window=right:60%' '--cycle'
            )
            [[ -n "$initial_query" ]] && fzf_options+=("--query=$initial_query")
            selected_file=$(find . -maxdepth 5 -type f 2>/dev/null \
              | fzf "''${fzf_options[@]}")
            [[ -n "$selected_file" && -f "$selected_file" ]] \
              && ''${EDITOR:-nvim} "$selected_file"
          }

          # ffec: fuzzy edit by content — grep for text, open matching file
          function _fuzzy_edit_search_file_content() {
            local selected_file
            local preview_cmd
            command -v bat &>/dev/null \
              && preview_cmd='bat --color always --style=plain --paging=never {}' \
              || preview_cmd='cat {}'
            selected_file=$(grep -irl "''${1:-}" ./ \
              | fzf --height=80% --layout=reverse --cycle \
                    --preview-window=right:60% --preview "$preview_cmd")
            [[ -n "$selected_file" ]] && ''${EDITOR:-nvim} "$selected_file"
          }

          # ffch: fuzzy command history search (replaces default Ctrl-R with richer UI)
          function _fuzzy_search_cmd_history() {
            local selected
            selected=$(fc -rl 1 \
              | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' \
              | fzf --height=80% --layout=reverse --scheme=history \
                    --bind='ctrl-r:toggle-sort' --query="''${LBUFFER}" +m)
            [[ -n "$selected" ]] && LBUFFER="$selected"
          }

          # ── ZSH Autosuggestions Tuning ─────────────────────────────────────────
          # history first, then completion engine — same as HyDE's setup
          export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
          export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20  # don't suggest for very long lines

          # ── Terminal Startup: fastfetch ────────────────────────────────────────
          # Only fire in interactive shells, not in scripts or SSH sessions without TTY.
          # do_render checks the terminal emulator for image protocol support.
          if [[ $- == *i* ]] && command -v fastfetch &>/dev/null; then
            if do_render "image"; then
              fastfetch --logo-type kitty  # kitty image protocol: crisp pixel-art logo
            else
              fastfetch                    # text logo fallback for other terminals
            fi
          fi
        ''
      ];

      # ── Shell Aliases ─────────────────────────────────────────────────────────
      shellAliases = {
        # ── Navigation ───────────────────────────────────────────────────────
        ".." = "cd ..";
        "..." = "cd ../..";
        ".3" = "cd ../../..";
        ".4" = "cd ../../../..";
        ".5" = "cd ../../../../..";
        "home" = "cd $HOME/DATA/FILES/";
        "proj" = "cd $HOME/DATA/FILES/PROJECTS";
        "docs" = "cd $HOME/Documents";

        # ── fzf Fuzzy Helpers (defined as functions in initExtra above) ───────
        "ffcd" = "_fuzzy_change_directory";
        "ffe" = "_fuzzy_edit_search_file";
        "ffec" = "_fuzzy_edit_search_file_content";
        "ffch" = "_fuzzy_search_cmd_history";

        # ── Editors ───────────────────────────────────────────────────────────
        "n" = "nvim";
        "v" = "vim";

        # ── System Conveniences ───────────────────────────────────────────────
        "c" = "clear";
        "cls" = "clear && ls";
        "cla" = "clear && ls -lah";
        "cp" = "cp -r"; # recursive by default (your preference)
        "mkdir" = "mkdir -p"; # create parent dirs automatically
        "open" = "xdg-open"; # open files with default app

        # ── Listing (use eza if available, fall back to ls) ───────────────────
        # eza is a modern ls replacement with icons, git status, tree view.
        # It's declared in modules/common/cli.nix. The fallback means this
        # alias is safe even before HM applies on a fresh install.

        # "ls" = "eza --icons --group-directories-first 2>/dev/null || ls --color=auto";   # <- Finicky
        # "ll" = "eza -lh --icons --group-directories-first --git 2>/dev/null || ls -lh";   # <- Finicky
        # "la" = "eza -lah --icons --group-directories-first --git 2>/dev/null || ls -lah"; # <- Finicky
        "l" = "eza --icons --group-directories-first";
        "ls" = "ls --color=auto";
        "la" = "ls -lah";
        "e" = "eza --icons";

        # "tree" = "eza --tree --icons 2>/dev/null || tree"; # <- Finicky
        "tree" = "_tree_wrapper";
        "et" = "eza --tree --icons";

        # ── Git ───────────────────────────────────────────────────────────────
        # OMZ git plugin provides the heavy aliases (gst, gco, gp, gl, etc.)
        # These are the ones not covered by OMZ or that override it.
        "g" = "git";
        "gs" = "git status";
        "gd" = "git diff";
        "gl" = "git log --oneline --graph --decorate";

        # ── Docker ────────────────────────────────────────────────────────────
        "d" = "docker";
        "dc" = "docker compose";
        "dps" = "docker ps";
        "dpa" = "docker ps -a";
        "di" = "docker images";

        # ── Application Fixes ─────────────────────────────────────────────────
        # Brave sometimes leaves a stale lock file and refuses to start.
        "bravefix" =
          "rm -f ~/.config/BraveSoftware/Brave-Browser/SingletonLock ~/.config/BraveSoftware/Brave-Browser/SingletonSocket";

        # ── Nix / Home Manager ────────────────────────────────────────────────
        # Shortcuts for the commands typed most during CypherOS work.
        # Mirrors `home-manager.backupFileExtension = "hm-bak"` set for the
        # NixOS-integrated path in flake/hosts.nix. Standalone HM has no
        # equivalent Nix-level option — this flag is the only way to get
        # matching backup behavior when running HM independently.
        "hms" =
          "clear && home-manager switch -b hm-bk --flake $HOME/CYPHER_OS#cypher_whisperer@cypher-nixos";

        "nfu" = "clear && nix flake update --flake $HOME/CYPHER_OS";
        "nrs" =
          "clear && sudo nixos-rebuild switch --install-bootloader --flake $HOME/CYPHER_OS#cypher-nixos --impure";
        # Safe rebuild — always reinstalls bootloader
        "nrbt" =
          "clear && sudo nixos-rebuild boot --install-bootloader --flake $HOME/CYPHER_OS#cypher-nixos --impure";
        # Build only — for testing evaluation without committing
        "nrbd" = "clear && nixos-rebuild build --flake $HOME/CYPHER_OS#cypher-nixos --impure";

        # ──────────────────── Personal Tooling  ───────────────────────────────
        "design" =
          "node /home/cypher-whisperer/DATA/FILES/PROJECTS/PRIVATE/DEV_SCRIPTS/js_ts/js/design_tokens/bin/design.js";

        # ── Arduino / IoT ─────────────────────────────────────────────────────
        # The shellAliases attrset is a single attrset value assigned to shellAliases =.
        # Nix doesn't support // merging inline there, but since config is in scope
        # (the module receives it as an arg), use lib.mkMerge at the config level —
        # except the whole config block is already one attrset.
        # The cleanest fit given existing structure:
        #    add a lib.optionalAttrs call at the bottom of the shellAliases attrset as below:
        #
        # These aliases are only active when the Arduino subsystem is enabled
        # (cypher-os.arduino.enable = true). They interpolate the board FQBN
        # directly from the Arduino module option so there is a single source
        # of truth — changing cypher-os.arduino.fqbn in options propagates here
        # automatically on the next `home-manager switch`.
        #
        # ard-build:   compile the sketch in the current directory (error check)
        # ard-upload:  compile + upload; pass the port as the final argument
        #              e.g. ard-upload /dev/ttyACM0
        #              boards with CH340/FTDI adapters use /dev/ttyUSB0 instead
        # ard-monitor: open arduino-cli's built-in serial monitor at 9600 baud
        #              Ctrl-C to quit. Change baudrate to match Serial.begin() in sketch.
        # ard-boards:  list currently connected and detected boards
        # ard-lib:     search the Arduino library registry (pipe to grep to filter)
        #              e.g. ard-lib | grep -i "DHT"
      }
      // lib.optionalAttrs config.cypher-os.arduino.enable {
        "ard-build" = "arduino-cli compile --fqbn ${config.cypher-os.arduino.fqbn}";
        "ard-upload" = "arduino-cli compile --fqbn ${config.cypher-os.arduino.fqbn} --upload --port";
        "ard-monitor" = "arduino-cli monitor --port /dev/ttyACM0 --config baudrate=9600";
        "ard-boards" = "arduino-cli board list";
        "ard-lib" = "arduino-cli lib search";
      };

      # ── sessionVariables ──────────────────────────────────────────────────────
      # Variables set for interactive login shells and exported to child processes.
      # Tool-specific variables that need to be available to GUI apps launched from
      # the terminal (e.g. EDITOR, VISUAL) go here rather than in initExtra
      # so they're set early in the session.
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    # ── fzf ─────────────────────────────────────────────────────────────────────
    # programs.fzf wires fzf into zsh properly: generates the shell integration
    # script and sets default options. The fzf package itself is in common/cli.nix.
    programs.fzf = {
      enable = true;
      enableZshIntegration = true; # sources fzf key-bindings and completion

      # Default options: applied to every fzf invocation unless overridden.
      # --height: don't take over the full terminal
      # --layout=reverse: results appear below the prompt (feels more natural)
      # --border: subtle border around the widget
      # --preview-window: default position for preview panes
      defaultOptions = [
        "--height=40%"
        "--layout=reverse"
        "--border=rounded"
        "--info=inline"
        "--preview-window=right:55%:wrap"
      ];
    };

    # ─────────────────────────────────────────────────────────────────────────────
    # P10K CONFIG FILE DEPLOYMENT
    # ─────────────────────────────────────────────────────────────────────────────
    # The .p10k.zsh file is too large to inline in initExtra cleanly. It's deployed
    # as a raw file via home.file and sourced from initExtra above.
    #
    # source path: configs/shell/p10k.zsh in the cypher-system repo
    # deploy path: ~/.config/zsh/.p10k.zsh  (inside ZDOTDIR)
    #
    # The file is managed by HM — don't edit it at the deployed path. Run
    # `p10k configure` to regenerate it, then copy the result back to
    # configs/shell/p10k.zsh in the repo and commit.
    home.file.".config/zsh/.p10k.zsh" = {
      source = "${self}/configs/shell/p10k.zsh";
    };
  };
}
