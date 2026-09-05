# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/cli/hm.nix
# ──────────────────────────────────────────────────────────────────────────────
# Home Manager module for btop system monitor.
#
# WHAT THIS FILE OWNS:
#   - btop.conf (deployed via xdg.configFile — btop writes its own runtime
#     state to this file, so we use xdg.configFile rather than programs.btop
#     to avoid HM ownership conflicts on settings btop updates at runtime)
#
#   - Catppuccin Mocha theme file deployment
#
# This module deploys the theme file to the correct XDG path and references
# it without shell variables, which btop can resolve correctly.
# ──────────────────────────────────────────────────────────────────────────────

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.cypher-os.pkgs.cli;

  # ────────────────────────────────────────────────────────────────────────────
  # Catppuccin btop theme source — fetch from the official repo.
  # This gives us the theme files (from a pinned version/commit) without
  # bundling them in the repo.
  # ────────────────────────────────────────────────────────────────────────────
  catppuccinBtop = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "btop";
    rev = "1.0.0";
    sha256 = "sha256-J3UezOQMDdxpflGax0rGBF/XMiKqdqZXuX4KMVGTxFk=";
  };

in
{
  config = lib.mkIf (cfg.enable && cfg.btop.enable) {
    home.packages = with pkgs; [
      btop
    ];

    # ── Theme Files ───────────────────────────────────────────────────────────
    # Deploy all four Catppuccin variants inorder to switch in btop's UI.
    # The active theme is set in btop.conf below (Mocha).
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."btop/themes/catppuccin_mocha.theme".source =
      "${catppuccinBtop}/themes/catppuccin_mocha.theme";
    xdg.configFile."btop/themes/catppuccin_macchiato.theme".source =
      "${catppuccinBtop}/themes/catppuccin_macchiato.theme";
    xdg.configFile."btop/themes/catppuccin_frappe.theme".source =
      "${catppuccinBtop}/themes/catppuccin_frappe.theme";
    xdg.configFile."btop/themes/catppuccin_latte.theme".source =
      "${catppuccinBtop}/themes/catppuccin_latte.theme";

    # ── btop Configuration ────────────────────────────────────────────────────
    # xdg.configFile writes the file but does NOT make it a managed symlink into
    # the Nix store. btop updates this file at runtime when settings change vis
    # its UI — a Nix store symlink would make that read-only.
    #
    # Using home.file with the onChange hook would conflict. Plain
    # xdg.configFile with force = true on initial deploy is the right balance.
    # ──────────────────────────────────────────────────────────────────────────
    xdg.configFile."btop/btop.conf" = {
      text = ''
        #? Config file for btop — managed by Home Manager (modules/apps/btop.nix)
        #? Runtime changes made in btop's UI will be preserved across sessions
        #? but will be overwritten if you run home-manager switch.
        #? To make a setting permanent, update this module and switch.

        # ── Theme ────────────────────────────────────────────────────────────────
        # Path is relative to btop's config directory — no shell expansion needed.
        # btop resolves this against $XDG_CONFIG_HOME/btop/ automatically.
        color_theme = "themes/catppuccin_mocha.theme"
        theme_background = False
        truecolor = True

        # ── Layout ───────────────────────────────────────────────────────────────
        shown_boxes = "cpu mem net proc"
        presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"

        # ── Process View ─────────────────────────────────────────────────────────
        proc_sorting = "cpu direct"
        proc_reversed = True
        proc_tree = True
        proc_colors = True
        proc_gradient = True
        proc_per_core = True
        proc_mem_bytes = True
        proc_cpu_graphs = True
        proc_info_smaps = False
        proc_left = False
        proc_filter_kernel = False
        proc_aggregate = False

        # ── CPU ──────────────────────────────────────────────────────────────────
        cpu_graph_upper = "total"
        cpu_graph_lower = "total"
        cpu_invert_lower = True
        cpu_single_graph = False
        cpu_bottom = False
        show_uptime = True
        check_temp = True
        cpu_sensor = "Auto"
        show_coretemp = True
        temp_scale = "celsius"
        show_cpu_freq = True
        show_gpu_info = "Auto"

        # ── Memory ───────────────────────────────────────────────────────────────
        mem_graphs = True
        mem_below_net = False
        show_swap = True
        swap_disk = True
        zfs_arc_cached = True
        show_disks = False

        # ── Disk ─────────────────────────────────────────────────────────────────
        # use_fstab reads your mounted partitions — useful for seeing @home and @data
        use_fstab = True
        only_physical = True
        show_io_stat = True
        io_mode = False
        io_graph_combined = False

        # ── Network ──────────────────────────────────────────────────────────────
        net_download = 100
        net_upload = 100
        net_auto = False
        net_sync = True

        # ── Display ──────────────────────────────────────────────────────────────
        graph_symbol = "braille"
        graph_symbol_cpu = "default"
        graph_symbol_gpu = "default"
        graph_symbol_mem = "default"
        graph_symbol_net = "default"
        graph_symbol_proc = "default"
        rounded_corners = True
        # vim_keys off — h conflicts with "help" and k with "kill" in btop
        vim_keys = False
        clock_format = "%X"
        background_update = True
        base_10_sizes = True
        force_tty = False
        update_ms = 2000

        # ── GPU ──────────────────────────────────────────────────────────────────
        nvml_measure_pcie_speeds = True
        gpu_mirror_graph = True

        # ── Battery ──────────────────────────────────────────────────────────────
        show_battery = False
        selected_battery = "Auto"

        # ── Logging ──────────────────────────────────────────────────────────────
        log_level = "WARNING"
      '';
    };
  };

}
