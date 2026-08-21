{
  config,
  lib,
  ...
}:

let
  cfg = config.cypher-os.apps.dev.languages.go;
in
{
  # ────────────────────────────────────────────────────────────────────────────
  # This file is intentionally thin. Go support in CypherOS is entirely
  # Home Manager-owned (programs.go, home.packages) per the flake's
  # single-source-of-truth architecture — there's no system-level Go
  # toolchain to declare.
  #
  # What lives here is the handful of NixOS-context knobs that only make sense
  # at the system level and that a serious Go dev session may eventually want.
  # ────────────────────────────────────────────────────────────────────────────
  config =
    lib.mkIf
      (config.cypher-os.apps.dev.enable && config.cypher-os.apps.dev.languages.enable && cfg.enable)
      {

        # ── Static linking support ────────────────────────────────────────────────
        # `go build -ldflags "-linkmode external -extldflags -static"` fails
        # on NixOS with `cannot find -lpthread`/`cannot find -lc` unless a
        # static glibc is present.
        #
        # Uncomment if/when a project needs fully static Go binaries (common for
        # minimal container images).
        # ──────────────────────────────────────────────────────────────────────────
        # environment.systemPackages = [ pkgs.glibc.static ];

        # ── Delve + hardening ─────────────────────────────────────────────────────
        # NixOS's default hardening flags (specifically _FORTIFY_SOURCE) have
        # historically broken delve when it's driving a debug session (surfaces
        # as a _FORTIFY_SOURCE error from VSCode or Neovim's DAP client).
        #
        # This is a per-derivation `hardeningDisable = [ "fortify" ]` concern inside
        # a project's own devShell, not a system-wide toggle — noted here so
        # the failure mode is documented somewhere if it resurfaces.
        # ──────────────────────────────────────────────────────────────────────────

        # ── Remote debugging over the network ─────────────────────────────────────
        # `dlv --headless --listen=:PORT` (or nvim-dap's `dap.adapters.delve`
        # in "remote"/"attach" mode) needs an open port if debugging something
        # running in a container/VM rather than locally. Off by default — local
        # debug sessions bind to localhost and never touch the firewall.
        # delve's conventional default port is 2345.
        # ──────────────────────────────────────────────────────────────────────────
        # networking.firewall.allowedTCPPorts = [ 2345 ];
      };
}
