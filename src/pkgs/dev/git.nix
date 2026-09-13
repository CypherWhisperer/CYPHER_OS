# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/git.nix
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
#   - Git identity (name, email) setting.
#   - Core behaviour (defaultBranch, editor, pull strategy, push defaults)
#   - Git LFS declaration (enabled but minimal — you can remove if unused)
#   - Useful aliases
#   - Delta as the pager (syntax-highlighted diffs)
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE DOES NOT OWN:
# ──────────────────────────────────────────────────────────────────────────────
#   - SSH keys (generated manually, never in the repo)
#   - SSH config (./ssh.nix)
#   - Credentials / tokens
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev;
  gitIdentityName = cypherOsConstants.gitIdentity.name;
  gitIdentityEmail = cypherOsConstants.gitIdentity.email;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.git.enable) {

    home.packages = with pkgs; [
      git-lfs

      # ────────────────────────────────────────────────────────────────────────
      # git pager (pulled in by programs.git.delta but good to be explicit)
      # ────────────────────────────────────────────────────────────────────────
      delta
    ];

    programs.git = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # SIGNING FORMAT.
      # ────────────────────────────────────────────────────────────────────────
      # Explicitly set to null to adopt the new default and silence the warning.
      # ────────────────────────────────────────────────────────────────────────
      # NOTE:
      # ────────────────────────────────────────────────────────────────────────
      # If using commit signing (GPG or SSH), update accordingly.
      # ────────────────────────────────────────────────────────────────────────
      signing.format = null;

      # ────────────────────────────────────────────────────────────────────────
      # GIT LFS.
      # ────────────────────────────────────────────────────────────────────────
      # Declares the LFS filter. Only activates for repos that have LFS objects.
      # ────────────────────────────────────────────────────────────────────────
      lfs.enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # SETTINGS.
      # ────────────────────────────────────────────────────────────────────────
      # programs.git.settings is the new unified home for identity,
      # core behaviour, and aliases (previously split across userName,
      # userEmail, extraConfig, aliases).
      # ────────────────────────────────────────────────────────────────────────
      settings = {
        # ──────────────────────────────────────────────────────────────────────
        # IDENTITY.
        # ──────────────────────────────────────────────────────────────────────
        user.name = gitIdentityName;
        user.email = gitIdentityEmail;

        # ──────────────────────────────────────────────────────────────────────
        # CORE BEHAVIOR.
        # ──────────────────────────────────────────────────────────────────────
        init.defaultBranch = "master";

        # ──────────────────────────────────────────────────────────────────────
        # Pull strategy: merge (false = create merge commit on diverged pull).
        # Honest history — you can see where things came from.
        # Switch to rebase = true when comfortable with git workflows.
        # ──────────────────────────────────────────────────────────────────────
        pull.rebase = false;

        # ──────────────────────────────────────────────────────────────────────
        # push.autoSetupRemote: automatically set the upstream on first push
        # of a new branch. Saves typing `--set-upstream origin <branch>`.
        # ──────────────────────────────────────────────────────────────────────
        push.autoSetupRemote = true;

        # ──────────────────────────────────────────────────────────────────────
        # core.editor: nvim for commit messages, rebase todo lists, etc.
        # ──────────────────────────────────────────────────────────────────────
        core.editor = if config.cypher-os.pkgs.dev.ide.neovim.enable == true then "nvim" else "";

        # ──────────────────────────────────────────────────────────────────────
        # core.autocrlf: never mangle line endings (you're on Linux everywhere)
        # ──────────────────────────────────────────────────────────────────────
        core.autocrlf = false;

        # ──────────────────────────────────────────────────────────────────────
        # merge.conflictstyle: show the common ancestor in conflict markers.
        # Makes conflicts easier to reason about than the default two-way diff.
        # ──────────────────────────────────────────────────────────────────────
        merge.conflictstyle = "diff3";

        # ──────────────────────────────────────────────────────────────────────
        # diff.colorMoved: colour moved lines differently from added/removed.
        # Makes refactors (moving code around) much easier to read in diffs.
        # ──────────────────────────────────────────────────────────────────────
        diff.colorMoved = "default";

        # ──────────────────────────────────────────────────────────────────────
        # rerere.enabled: remember how you resolved a conflict and replay it
        # automatically if the same conflict appears again (e.g. after rebase).
        # ──────────────────────────────────────────────────────────────────────
        rerere.enabled = true;

        # ──────────────────────────────────────────────────────────────────────
        # column.ui: use column layout for branch listings and similar output.
        # ──────────────────────────────────────────────────────────────────────
        column.ui = "auto";

        # ──────────────────────────────────────────────────────────────────────
        # branch.sort: show most recently used branches first in `git branch`.
        # ──────────────────────────────────────────────────────────────────────
        branch.sort = "-committerdate";

        # ──────────────────────────────────────────────────────────────────────
        # ALIASES.
        # ──────────────────────────────────────────────────────────────────────
        # These complement the OMZ git plugin aliases already in zsh.nix.
        # OMZ covers: gst (status), gco (checkout), gp (push), gl (pull), etc.
        # These add the ones OMZ doesn't have or that you'll use differently.
        # ──────────────────────────────────────────────────────────────────────
        alias = {
          # ────────────────────────────────────────────────────────────────────
          # Pretty log — one line per commit with graph, colours, relative dates
          # ────────────────────────────────────────────────────────────────────
          lg = "log --oneline --graph --decorate --all";
          lga = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";

          # ────────────────────────────────────────────────────────────────────
          # Undo last commit, keep changes staged
          # ────────────────────────────────────────────────────────────────────
          undo = "reset --soft HEAD~1";

          # ────────────────────────────────────────────────────────────────────
          # Stage all changes and commit with message: `git save 'wip'`
          # ────────────────────────────────────────────────────────────────────
          save = "!git add -A && git commit -m";

          # ────────────────────────────────────────────────────────────────────
          # Show files changed in the last commit
          # ────────────────────────────────────────────────────────────────────
          last = "diff HEAD~1 HEAD --name-only";

          # ────────────────────────────────────────────────────────────────────
          # List all branches sorted by last commit date
          # ────────────────────────────────────────────────────────────────────
          branches = "branch --sort=-committerdate --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:green)(%(committerdate:relative))%(color:reset) %(contents:subject)'";

          # ────────────────────────────────────────────────────────────────────
          # Discard all unstaged changes
          # ────────────────────────────────────────────────────────────────────
          discard = "checkout --";

          # ────────────────────────────────────────────────────────────────────
          # Show the diff of what's staged (about to be committed)
          # ────────────────────────────────────────────────────────────────────
          staged = "diff --cached";

          # ────────────────────────────────────────────────────────────────────
          # Quick amend last commit (no message change)
          # ────────────────────────────────────────────────────────────────────
          amend = "commit --amend --no-edit";
        };
      };

      # ────────────────────────────────────────────────────────────────────────
      # GLOBAL IGNORES.
      # ────────────────────────────────────────────────────────────────────────
      # Files to ignore in every repository — things that should never be
      # committed regardless of project type.
      # ────────────────────────────────────────────────────────────────────────
      ignores = [
        # ──────────────────────────────────────────────────────────────────────
        # OS and editor artifacts
        # ──────────────────────────────────────────────────────────────────────
        ".DS_Store"
        "Thumbs.db"
        ".directory"

        # ──────────────────────────────────────────────────────────────────────
        # Editor state files
        # ──────────────────────────────────────────────────────────────────────
        "*.swp"
        "*.swo"
        "*~"
        ".vim/"
        ".nvim/"

        # ──────────────────────────────────────────────────────────────────────
        # Nix build artifacts
        # ──────────────────────────────────────────────────────────────────────
        "result"
        "result-*"

        # ──────────────────────────────────────────────────────────────────────
        # Environment and secrets files; belt-&-suspenders alongside .gitignore.
        # ──────────────────────────────────────────────────────────────────────
        ".env"
        ".env.local"
        ".env.*.local"
        "secrets/env"
        "*.age" # encrypted age secrets (except when intentionally committed)

        # ──────────────────────────────────────────────────────────────────────
        # Node
        # ──────────────────────────────────────────────────────────────────────
        "node_modules/"
        ".npm/"

        # ──────────────────────────────────────────────────────────────────────
        # Python
        # ──────────────────────────────────────────────────────────────────────
        "__pycache__/"
        "*.py[cod]"
        ".venv/"
        "venv/"

        # ──────────────────────────────────────────────────────────────────────
        # Logs
        # ──────────────────────────────────────────────────────────────────────
        "*.log"
      ];
    };

    # ──────────────────────────────────────────────────────────────────────────
    # DELTA PAGER.
    # ──────────────────────────────────────────────────────────────────────────
    # delta: a syntax-highlighting pager for git diffs, log, and blame.
    # Replaces the default `less` output with coloured, side-by-side-capable
    # diffs.  Moved out of programs.git per the deprecation rename.
    # ──────────────────────────────────────────────────────────────────────────
    programs.delta = {
      enable = true;
      # ────────────────────────────────────────────────────────────────────────
      # explicit — silences the deprecation warning
      # ────────────────────────────────────────────────────────────────────────
      enableGitIntegration = true;

      options = {
        line-numbers = true;

        # ──────────────────────────────────────────────────────────────────────
        # n/N to move between diff sections
        # ──────────────────────────────────────────────────────────────────────
        navigate = true;

        # ──────────────────────────────────────────────────────────────────────
        # unified diff by default; toggle with `delta --side-by-side`
        # ──────────────────────────────────────────────────────────────────────
        side-by-side = false;

        # ──────────────────────────────────────────────────────────────────────
        # matches terminal palette
        # ──────────────────────────────────────────────────────────────────────
        features = lib.mkForce "catppuccin-mocha decorations";

        # ──────────────────────────────────────────────────────────────────────
        # catppuccin/nix now handles the theming system-wide/ globally
        # ──────────────────────────────────────────────────────────────────────
        #syntax-theme = "Catppuccin-mocha";

        decorations = {
          commit-decoration-style = "blue ol";
          commit-style = "raw";
          file-style = "omit";
          hunk-header-decoration-style = "blue box";
          hunk-header-file-style = "red";
          hunk-header-line-number-style = "#067a00";
          hunk-header-style = "file line-number syntax";
        };
      };
    };
  };
}
