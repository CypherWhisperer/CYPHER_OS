# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/dev/ide/neovim.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
# - Neovim binary installation and core settings
# - NVIM_APPNAME-based aliases for each distro and CypherIDE
# - nvim-add / nvim-rm script deployment to ~/.local/bin/
# - xdg.configFile deployment for CypherIDE (configs/editor/cypher-ide/)
# - nvim-aliases.zsh sourcing hook (the runtime-generated aliases file)
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE DOES NOT OWN:
# ──────────────────────────────────────────────────────────────────────────────
# - Distro contents — cloned at first use via nvim-add or manually
# - CypherIDE plugins — managed by lazy.nvim inside the Lua config
# - Language servers — installed by Mason inside CypherIDE (not system-wide)
#
# ──────────────────────────────────────────────────────────────────────────────
# NVIM_APPNAME STRATEGY:
# ──────────────────────────────────────────────────────────────────────────────
# Each config lives at $XDG_CONFIG_HOME/<appname>/
# Under XDG profile separation this resolves to the per-DE profile path,
# so distro configs are naturally isolated per DE session.
#
# Aliases declared here are static (the named distros).
# Aliases for configs created via nvim-add are written to
# ~/.config/zsh/nvim-aliases.zsh at runtime and sourced by zsh.nix.
#
# ──────────────────────────────────────────────────────────────────────────────
# DISTRO CLONING:
# ──────────────────────────────────────────────────────────────────────────────
# Distros are NOT cloned by Nix/HM. Nix manages the binary and config
# deployment; distro cloning is a one-time manual step or handled by nvim-add.
# This keeps the flake hermetic — no network calls at switch time.
#
# ──────────────────────────────────────────────────────────────────────────────
# TO ADD A DISTRO AFTER FIRST INSTALL:
# ──────────────────────────────────────────────────────────────────────────────
# nvim-add nvchad https://github.com/NvChad/starter
# nvim-add lazy   https://github.com/LazyVim/starter
# nvim-add astro  https://github.com/AstroNvim/template
# nvim-add kick   https://github.com/nvim-lua/kickstart.nvim
# nvim-add lunar  https://github.com/LunarVim/LunarVim   # archived, read-only
#
# ──────────────────────────────────────────────────────────────────────────────
# MINI.NVIM AS REFERENCE:
# ──────────────────────────────────────────────────────────────────────────────
# mini.nvim is a collection of modules to study, not a daily-driver distro.
# Clone it with: nvim-add mini-ref https://github.com/echasnovski/mini.nvim
# No launch alias is generated — browse its source as a library reference.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.pkgs.dev.ide;
  cypherIdeRepo = cypherOsConstants.cypherIdeRepoRoot;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.neovim.enable) {
    # ──────────────────────────────────────────────────────────────────────────
    # NEOVIM BINARY
    # ──────────────────────────────────────────────────────────────────────────
    programs.neovim = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # viAlias / vimAlias: typing `vi` or `vim` launches nvim. This is separate
      # from the vim notepad (src/pkgs/editor/vim.nix) — that module installs
      # actual vim for the `v` alias. These aliases exist so scripts or muscle
      # memory that types `vi` still works.
      # ────────────────────────────────────────────────────────────────────────
      viAlias = false; # vim.nix owns `v`; avoiding shadowing it
      vimAlias = false; # same reasoning

      # ────────────────────────────────────────────────────────────────────────
      # withNodeJs / withPython3 / withRuby:
      # ────────────────────────────────────────────────────────────────────────
      # These embed provider support directly into the Neovim build.
      #
      # Node: required by some older plugins and Copilot.
      # Python3: required by any plugin using the pynvim RPC provider.
      # Ruby: almost no modern plugins require this. Off.
      # ────────────────────────────────────────────────────────────────────────
      withNodeJs = true;
      withPython3 = true;
      withRuby = false;

      # ────────────────────────────────────────────────────────────────────────
      # extraPackages: tools that must be on PATH when Neovim runs.
      # These are injected into Neovim's wrapper PATH — not the shell PATH.
      # Covers tools that Mason (inside CypherIDE) or telescope.nvim call out to
      # ────────────────────────────────────────────────────────────────────────
      extraPackages = with pkgs; [

        # ──────────────────────────────────────────────────────────────────────
        # Telescope dependencies
        # ──────────────────────────────────────────────────────────────────────
        ripgrep # telescope live_grep backend
        fd # telescope file finder backend

        # ──────────────────────────────────────────────────────────────────────
        # Clipboard providers (Wayland-first, X11 fallback —
        # matches zsh.nix choice)
        # ──────────────────────────────────────────────────────────────────────
        wl-clipboard # wl-copy / wl-paste
        xclip # fallback for X11 / XWayland sessions

        # ──────────────────────────────────────────────────────────────────────
        # Tree-sitter CLI — needed by nvim-treesitter to compile parsers
        # (CypherIDE uses lazy.nvim + nvim-treesitter which calls this
        # at runtime)
        # ──────────────────────────────────────────────────────────────────────
        tree-sitter

        # ──────────────────────────────────────────────────────────────────────
        # Mason's external tool installers need these in PATH
        # ──────────────────────────────────────────────────────────────────────
        unzip # many Mason packages are distributed as zip archives
        wget
        curl
        git

        # For building telescope-fzf-native
        gnumake
        gcc
        libgcc
      ];

      # ────────────────────────────────────────────────────────────────────────
      # plugins:
      # ────────────────────────────────────────────────────────────────────────
      # CypherIDE uses lazy.nvim (declared in init.lua) to manage its
      # own plugins. Beware Mixing Nix-managed and lazy.nvim-managed plugins in
      # the same config causes load order conflicts.
      # ────────────────────────────────────────────────────────────────────────
      plugins = with pkgs.vimPlugins; [

        # ──────────────────────────────────────────────────────────────────────
        # Install lazy.nvim via Nix so the bootstrap git clone is never needed.
        # lazy.nvim will still manage all other plugins itself at runtime.
        # ──────────────────────────────────────────────────────────────────────
        lazy-nvim
      ];

      # ────────────────────────────────────────────────────────────────────────
      # extraConfig: intentionally empty.
      # ────────────────────────────────────────────────────────────────────────
      # CypherIDE's init.lua lives in src/pkgs/dev/ide/configs/cypher-ide/ and
      # is deployed via xdg.configFile below.
      #
      # Don't put Lua here — it would be prepended to every NVIM_APPNAME config,
      # including the distros.
      # ────────────────────────────────────────────────────────────────────────
      extraConfig = "";
      # ────────────────────────────────────────────────────────────────────────
      # If ever needed:
      # ────────────────────────────────────────────────────────────────────────
      #extraLuaConfig = ''
      # require("lazy").setup({
      #   spec = {
      #    { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "bash", "cmake" } } },
      #    -- Add other plugins here
      #   }
      # })
      #'';
      # ────────────────────────────────────────────────────────────────────────
    };

    # ──────────────────────────────────────────────────────────────────────────
    # CYPHER-IDE CONFIG DEPLOYMENT
    # ──────────────────────────────────────────────────────────────────────────
    # Deploys the CypherIDE Lua config from the repo into the XDG config path
    # that NVIM_APPNAME=cypher-ide resolves to.
    #
    # source: src/pkgs/dev/ide/configs/cypher-ide/ (i.e, init.lua and lua/ tree)
    # target: $XDG_CONFIG_HOME/cypher-ide/ (what Neovim reads at runtime)
    #
    # The source directory starts with a minimal init.lua
    # (seeded from Kickstart). Grow it at will — `home-manager switch` redeploys
    # it automatically.
    #
    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: xdg.configFile creates symlinks into the Nix store. This means the
    # deployed files are read-only. To edit CypherIDE config, edit the source
    # in src/pkgs/dev/ide/configs/cypher-ide/ and run home-manager switch.
    # Do NOT edit files at ~/.config/profiles/gnome/cypher-ide/ directly.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."cypher-ide" = {
      # ────────────────────────────────────────────────────────────────────────
      # mkOutOfStoreSymlink creates a direct symlink to the source path, NOT a
      # copy in the Nix store. The deployed symlink points straight at CypherIDE
      # repo directory, (i.e., a real mutable path on disk).
      #
      # This means edits to configs/editor/cypher-ide/ take effect immediately
      # without `home-manager switch`.
      #
      # ────────────────────────────────────────────────────────────────────────
      #recursive = true; # deploy the whole directory tree, not just single file
      # ────────────────────────────────────────────────────────────────────────
      source = config.lib.file.mkOutOfStoreSymlink cypherIdeRepo;
    };

    # ──────────────────────────────────────────────────────────────────────────
    # STATIC ALIASES — NAMED DISTROS + CYPHER-IDE
    # ──────────────────────────────────────────────────────────────────────────
    # These are written into the shell by Home Manager.
    # Dynamic aliases (from nvim-add) live in ~/.config/zsh/nvim-aliases.zsh.
    #
    # No bare `nvim` alias — typing nvim launches Neovim without NVIM_APPNAME,
    # which reads $XDG_CONFIG_HOME/nvim/.
    #
    # That directory is intentionally left empty (or minimal) so there's no
    # accidental default config to fall back on. Every launch is explicit.
    # ──────────────────────────────────────────────────────────────────────────
    home.shellAliases = {
      "cide" = "NVIM_APPNAME=cypher-ide nvim";
      "nvchad" = "NVIM_APPNAME=nvchad nvim";
      "lazy" = "NVIM_APPNAME=lazy nvim";
      "astro" = "NVIM_APPNAME=astro nvim";
      "kick" = "NVIM_APPNAME=kick nvim";
      "lunar" = "NVIM_APPNAME=lunar nvim";
      # ────────────────────────────────────────────────────────────────────────
      # mini-ref has no launch alias intentionally — it's a reference library,
      # not a usable editor config. Browse it at:
      # ~/.config/profiles/gnome/mini-ref/
      # ────────────────────────────────────────────────────────────────────────
    };

    # ──────────────────────────────────────────────────────────────────────────
    # NVIM-ADD / NVIM-RM SCRIPTS
    # ──────────────────────────────────────────────────────────────────────────
    # Deployed to ~/.local/bin/ — already in PATH from zsh.nix.
    #
    # these home.file entries deploy the scripts from the repo to the executable
    # location.
    #
    # The scripts write to anr read from ~/.config/zsh/nvim-aliases.zsh.
    # zsh.nix sources that file if it exists (see the sourcing hook below).
    # ──────────────────────────────────────────────────────────────────────────
    home.file.".local/bin/nvim-add" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # nvim-add — create a new Neovim config or clone a distro
        #
        # Usage:
        #   nvim-add <name> [git-url]
        #
        #   nvim-add myconfig                              # blank config
        #   nvim-add nvchad https://github.com/NvChad/starter  # clone distro
        #
        # After running, the alias is available in new shell sessions.
        # Source ~/.config/zsh/nvim-aliases.zsh to get it in the current session.

        set -euo pipefail

        ALIASES_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/nvim-aliases.zsh"
        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}"

        name="''${1:-}"
        url="''${2:-}"

        if [[ -z "$name" ]]; then
          echo "Usage: nvim-add <name> [git-url]"
          exit 1
        fi

        # Validate name — alphanumeric, hyphens, underscores only
        if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
          echo "Error: name must be alphanumeric (hyphens and underscores allowed)"
          exit 1
        fi

        target="$CONFIG_DIR/$name"

        if [[ -d "$target" ]]; then
          echo "Error: $target already exists"
          exit 1
        fi

        # Create config directory
        if [[ -n "$url" ]]; then
          echo "Cloning $url into $target ..."
          git clone --depth=1 "$url" "$target"
          echo "Cloned."
        else
          mkdir -p "$target"
          echo "Created blank config at $target"
          echo "Add your init.lua to get started."
        fi

        # Append alias to the managed aliases file
        mkdir -p "$(dirname "$ALIASES_FILE")"
        touch "$ALIASES_FILE"

        # Check the alias doesn't already exist in the file
        if grep -q "alias ''${name}=" "$ALIASES_FILE" 2>/dev/null; then
          echo "Note: alias '$name' already exists in $ALIASES_FILE — not adding again"
        else
          echo "alias ''${name}=\"NVIM_APPNAME=''${name} nvim\"" >> "$ALIASES_FILE"
          echo "Alias '$name' added to $ALIASES_FILE"
        fi

        echo ""
        echo "Done. To use now:  source $ALIASES_FILE"
        echo "New shells will pick it up automatically."
      '';
    };

    home.file.".local/bin/nvim-rm" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # nvim-rm — remove a Neovim config and all associated data
        #
        # Usage:
        #   nvim-rm <name>
        #
        # Removes:
        #   $XDG_CONFIG_HOME/<name>/   config files
        #   $XDG_DATA_HOME/<name>/     plugin data, LSP servers, parsers
        #   $XDG_STATE_HOME/<name>/    shada (history), swap files
        #   $XDG_CACHE_HOME/<name>/    cached data
        #   The alias entry in ~/.config/zsh/nvim-aliases.zsh
        #
        # You are responsible for ensuring nothing important is in these
        # directories before running. This script does not archive anything.

        set -euo pipefail

        ALIASES_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/nvim-aliases.zsh"
        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}"
        DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}"
        STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}"
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}"

        name="''${1:-}"

        if [[ -z "$name" ]]; then
          echo "Usage: nvim-rm <name>"
          exit 1
        fi

        # Safety: refuse to remove statically declared configs
        protected=("cypher-ide" "nvchad" "lazy" "astro" "kick" "lunar")
        for p in "''${protected[@]}"; do
          if [[ "$name" == "$p" ]]; then
            echo "Error: '$name' is a statically declared config managed by Home Manager."
            echo "To remove it, delete the alias from modules/apps/neovim.nix and run home-manager switch."
            exit 1
          fi
        done

        removed=0

        for base in "$CONFIG_DIR" "$DATA_DIR" "$STATE_DIR" "$CACHE_DIR"; do
          target="$base/$name"
          if [[ -d "$target" ]]; then
            rm -rf "$target"
            echo "Removed $target"
            removed=1
          fi
        done

        # Remove alias from managed file
        if [[ -f "$ALIASES_FILE" ]]; then
          # Use a temp file to avoid in-place sed portability issues
          grep -v "alias ''${name}=" "$ALIASES_FILE" > "''${ALIASES_FILE}.tmp" \
            && mv "''${ALIASES_FILE}.tmp" "$ALIASES_FILE"
          echo "Removed alias '$name' from $ALIASES_FILE"
        fi

        if [[ $removed -eq 0 ]]; then
          echo "Nothing found for '$name' — no directories existed"
        else
          echo ""
          echo "Done. Unset the alias in the current session with:  unalias $name"
        fi
      '';
    };

    # ──────────────────────────────────────────────────────────────────────────
    # NVIM-ALIASES SOURCING HOOK
    # ──────────────────────────────────────────────────────────────────────────
    # This appends a sourcing line to zsh's initExtra so runtime-generated
    # aliases (from nvim-add) are loaded in every shell session.
    #
    # The file may not exist yet on a fresh install — the [[ -f ]] guard
    # prevents a startup error in that case.
    #
    # This works alongside zsh.nix because Home Manager merges all
    # programs.zsh.initExtra contributions from imported modules.
    # ──────────────────────────────────────────────────────────────────────────
    programs.zsh.initExtra = lib.mkAfter ''
      # nvim-add generated aliases (runtime — not managed by Home Manager)
      [[ -f "''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/nvim-aliases.zsh" ]] \
        && source "''${XDG_CONFIG_HOME:-$HOME/.config}/zsh/nvim-aliases.zsh"
    '';
  };
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: CHECK ON THE CYPHERIDE DEPLOYMENT
# ──────────────────────────────────────────────────────────────────────────────
#source = ../../configs/editor/cypher-ide;
# VS,
#
# PREVIOUS (OLD SCHOOL (i.e., before namespace and repo tree refactor)):
#  - source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/CYPHER_OS/configs/editor/cypher-ide";
# VS,
#
#source = config.lib.file.mkOutOfStoreSymlink "../../../configs/editor/cypher-ide";
#
# VS,
# CURRENT:
#  - source = config.lib.file.mkOutOfStoreSymlink cypherIdeRepo;
#
# ──────────────────────────────────────────────────────────────────────────────
# I Don't currently clearly remember the incident but I had to point it to the
# repo (this repo; since cypherIDE is a submodule of CypherOS) relative to
# $HOME (config.home.homeDirectory.)
#
# currently using the `self` pattern (src/config/constants/options.nix >>
# cypherIdeRepoRoot). Check and observe behavior after build.
#
# ──────────────────────────────────────────────────────────────────────────────
# mkOutOfStoreSymlink creates a direct symlink to the source path, NOT a
# copy in the Nix store. The deployed symlink points straight at CypherIDE
# repo directory, (i.e., a real mutable path on disk).
#
# This means edits to configs/editor/cypher-ide/ take effect immediately
# without `home-manager switch`.
# ──────────────────────────────────────────────────────────────────────────────
