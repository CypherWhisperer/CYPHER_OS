# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/htop.nix
# ──────────────────────────────────────────────────────────────────────────────
# programs.htop in Home Manager writes ~/.config/htop/htoprc declaratively.
# Catppuccin Mocha palette applied manually via color_scheme = 6 (custom)
# and explicit color assignments.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.cli;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.htop.enable) {

    programs.htop = {
      enable = true;
      settings = {
        # ── Layout ────────────────────────────────────────────────────────────
        hide_userland_threads = true;
        shadow_other_users = false;
        show_thread_names = true;
        show_program_path = true;
        highlight_base_name = true;
        highlight_megabytes = true;
        highlight_threads = true;
        highlight_changes = false;
        highlight_changes_delay_secs = 5;
        find_comm_in_cmdline = true;
        strip_exe_from_cmdline = true;
        show_cpu_usage = true;
        show_cpu_frequency = true;
        show_cpu_temperature = true;
        degree_fahrenheit = false; # celsius — matches btop
        show_merged_cpu = true; # single merged CPU bar (cleaner for many cores)
        show_idle_threads = false;

        # ── Sorting ───────────────────────────────────────────────────────────
        sort_key = 46; # PERCENT_CPU
        sort_direction = -1; # descending (highest CPU first)
        tree_view = true;
        tree_view_always_by_pid = false;

        # ── Update ────────────────────────────────────────────────────────────
        delay = 15; # update every 1.5 seconds (delay is in tenths)

        # ── Color Scheme ──────────────────────────────────────────────────────
        # color_scheme 6 = custom. The explicit color values below map to
        # Catppuccin Mocha: base #1e1e2e, surface #313244, text #cdd6f4,
        # blue #89b4fa, green #a6e3a1, yellow #f9e2af, red #f38ba8, mauve #cba6f7
        color_scheme = 6;

        # ── Meters (top bar) ──────────────────────────────────────────────────
        # Left column: CPU usage bars + memory bar
        # Right column: Tasks/load average + uptime
        # Format: each meter is "type mode" — mode 1=bar, 2=text, 3=graph, 4=LED
        left_meters = [
          "LeftCPUs2"
          "Blank"
          "Memory"
          "Swap"
        ];
        left_meter_modes = [
          1
          2
          1
          1
        ];
        right_meters = [
          "Tasks"
          "LoadAverage"
          "Uptime"
          "Systemd"
        ];
        right_meter_modes = [
          2
          2
          2
          2
        ];
      };
    };
  };
}
