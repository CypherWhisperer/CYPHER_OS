# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/editor/vim.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Home Manager module for Vim — configured as "minimal CLI notepad" to CypherOS.
#
# ──────────────────────────────────────────────────────────────────────────────
# PHILOSOPHY:
# ──────────────────────────────────────────────────────────────────────────────
# Vim serves one purpose here: open a file quickly, edit it, close it. No plugin
# manager. No LSP servers. No startup overhead.
#
# What it does have:
#  - Treesitter-quality syntax highlighting via vim's built-in syntax engine
#    + a manually curated polyglot syntax pack (vim-polyglot covers 600+
#    languages with maintained syntax files, zero runtime cost)
#
#  - System clipboard integration (wl-clipboard + xclip fallback)
#  - Comfortable editing defaults (line numbers, indentation, search)
#
# ──────────────────────────────────────────────────────────────────────────────
# WHY NOT TREESITTER FOR VIM:
# ──────────────────────────────────────────────────────────────────────────────
# nvim-treesitter is a Neovim plugin — it doesn't run in Vim.
#
# Vim's syntax engine is regex-based. vim-polyglot packages the best available
# syntax files for each language into one plugin, giving accurate highlighting
# for Python, JS/TS, Lua, Bash, Nix, and hundreds more.
#
# It's the correct Vim-native equivalent of Treesitter highlighting.
#
# ──────────────────────────────────────────────────────────────────────────────
# ALIAS:
# ──────────────────────────────────────────────────────────────────────────────
# `v` — defined in zsh.nix shellAliases, points to vim
# programs.vim.defaultEditor = false — nvim remains $EDITOR
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.editor;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.vim.enable) {

    programs.vim = {
      enable = true;

      # ────────────────────────────────────────────────────────────────────────
      # defaultEditor: if true, sets $EDITOR=vim. If $EDITOR=nvim (set in
      # zsh.nix sessionVariables), this will be false, and vice versa
      # ────────────────────────────────────────────────────────────────────────
      defaultEditor = true;

      # ────────────────────────────────────────────────────────────────────────
      # plugins: installed by Home Manager into Vim's package path.
      # No plugin manager needed — HM handles the runtimepath injection.
      # ────────────────────────────────────────────────────────────────────────
      plugins = with pkgs.vimPlugins; [
        # ──────────────────────────────────────────────────────────────────────
        # vim-polyglot: syntax highlighting for 600+ languages. Lazy-loads per
        # filetype — only the relevant syntax file is sourced when a file is
        # openned. Zero cost for filetypes not openned.
        # ──────────────────────────────────────────────────────────────────────
        vim-polyglot

        # ──────────────────────────────────────────────────────────────────────
        # dark colorscheme, clean and easy on the eyes.
        # ──────────────────────────────────────────────────────────────────────
        # Alternatives:
        #   tokyonight-nvim
        #   catppuccin-vim
        # Swap by changing the plugin name and the colorscheme line in
        # extraConfig (see below).
        # ──────────────────────────────────────────────────────────────────────
        #vim-nightfly-colors
        #catppuccin-vim
        #tokyonight-nvim
      ];

      extraConfig = ''
        " ── Core Settings ────────────────────────────────────────────────────────

        " Use Vim settings, not Vi settings. Must be first.
        set nocompatible

        " Enable filetype detection, plugins, and indent rules.
        " Required for vim-polyglot to activate per-filetype syntax files.
        filetype plugin indent on
        syntax enable

        " ── Appearance ───────────────────────────────────────────────────────────
        set termguicolors          " 24-bit true color (requires a capable terminal)
        " colorscheme tokyonight-night
        " colorscheme catpuccin_mocha

        set number                 " absolute line numbers
        set relativenumber         " relative numbers for easy jump targets (5j, 12k)
        set cursorline             " highlight the line the cursor is on
        set signcolumn=yes         " always show the sign column (no layout shift)
        set colorcolumn=100        " soft column guide at 100 chars

        " Ensure background is dark (some terminals override this)
        set background=dark

        " ── Editing Behaviour ────────────────────────────────────────────────────
        set expandtab              " insert spaces when Tab is pressed
        set tabstop=2              " a Tab character displays as 2 spaces
        set shiftwidth=2           " >> and << indent/dedent by 2 spaces
        set softtabstop=2          " backspace deletes 2 spaces as if a tab
        set autoindent             " copy indent from previous line
        set smartindent            " add extra indent for code blocks

        set wrap                   " wrap long lines visually (no horizontal scroll)
        set linebreak              " wrap at word boundaries, not mid-word
        set scrolloff=8            " keep 8 lines visible above/below cursor
        set sidescrolloff=8        " keep 8 columns visible left/right

        set backspace=indent,eol,start  " backspace works over everything in insert

        " ── Search ───────────────────────────────────────────────────────────────
        set incsearch              " highlight matches as you type
        set hlsearch               " highlight all matches after search
        set ignorecase             " case-insensitive search by default
        set smartcase              " case-sensitive if query contains uppercase

        " Clear search highlight with Esc in normal mode
        nnoremap <Esc> :nohlsearch<CR>

        " ── Clipboard ────────────────────────────────────────────────────────────
        " unnamed: y/p use the system clipboard (the one shared with your DE).
        " unnamedplus: same, but uses the + register (X11 clipboard / Wayland).
        " Both together means yank/paste always uses what you expect regardless
        " of whether you're in a Wayland or X11/XWayland session.
        "
        " Vim detects the clipboard provider at startup via:
        "   1. wl-copy / wl-paste  (wl-clipboard, Wayland)
        "   2. xclip               (X11 fallback)
        " Both are in Neovim's extraPackages and available in PATH.
        set clipboard=unnamed,unnamedplus

        " ── Files & History ──────────────────────────────────────────────────────
        set autoread               " reload file if changed on disk outside vim
        set hidden                 " allow switching buffers without saving
        set noswapfile             " no .swp files — you're editing quick notes
        set nobackup               " no backup~ files
        set undofile               " persistent undo across sessions
        " Put undo files in XDG state dir, not the file's directory
        let &undodir = expand('~/.local/state/vim/undo')
        silent! call mkdir(&undodir, 'p')

        " ── Key Maps ─────────────────────────────────────────────────────────────
        " Leader key — space (most common modern choice)
        let mapleader = " "

        " Save with <leader>w (faster than :w<Enter> for common task)
        nnoremap <leader>w :w<CR>

        " Quit with <leader>q
        nnoremap <leader>q :q<CR>

        " Save and quit with <leader>x
        nnoremap <leader>x :x<CR>

        " Move between buffers with Tab / Shift-Tab
        nnoremap <Tab>   :bnext<CR>
        nnoremap <S-Tab> :bprev<CR>

        " Move selected lines up/down in visual mode (J/K)
        vnoremap J :m '>+1<CR>gv=gv
        vnoremap K :m '<-2<CR>gv=gv

        " Keep cursor centered when scrolling
        nnoremap <C-d> <C-d>zz
        nnoremap <C-u> <C-u>zz

        " Keep cursor centered on search result jumps
        nnoremap n nzzzv
        nnoremap N Nzzzv

        " ── Status Line ──────────────────────────────────────────────────────────
        " Minimal built-in statusline — filename, modified flag, filetype, position.
        " No plugin needed.
        set laststatus=2           " always show statusline
        set statusline=\ %f        " filename
        set statusline+=\ %m       " modified flag [+]
        set statusline+=\ %r       " readonly flag [RO]
        set statusline+=%=         " switch to right side
        set statusline+=\ %y       " filetype [lua]
        set statusline+=\ %l:%c    " line:column
        set statusline+=\ %p%%\    " percentage through file

        " ── Completion ───────────────────────────────────────────────────────────
        " Built-in completion from current buffer, other open buffers, and file paths.
        " No LSP. Triggered with Ctrl-n / Ctrl-p in insert mode.
        set complete=.,b,u,]       " . = current buffer, b = other buffers,
                                  " u = unloaded buffers, ] = tag files
        set completeopt=menu,menuone,noselect

        " ── Misc ─────────────────────────────────────────────────────────────────
        set encoding=utf-8
        set fileencoding=utf-8
        set updatetime=250         " faster CursorHold events (used by some plugins)
        set timeoutlen=500         " ms to wait for mapped key sequence
        set showmatch              " briefly jump to matching bracket
        set matchtime=2            " how long to show the match (tenths of a second)
        set wildmenu               " enhanced command-line completion
        set wildmode=longest:full,full
      '';
    };
  };
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: Handle Proper Configuration alongside CypherIDE (Neovim (./neovim.nix))
# ──────────────────────────────────────────────────────────────────────────────
