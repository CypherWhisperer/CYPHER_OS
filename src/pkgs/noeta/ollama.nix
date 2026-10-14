# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/noeta/ollama.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.noeta;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.ollama.enable) {
      home.packages = with pkgs; [
        ollama
        gollama # Terminal TUI for managing pulled models.

        # ───────────────────────────────────────────────────────────────────────
        # Hardware-accelerated backend variants of the _same_ `ollama` —
        # confirmed on the [NixOS wiki](https://wiki.nixos.org/wiki/Ollama)
        # ───────────────────────────────────────────────────────────────────────
        #ollama-cuda # for Nvidia
        #ollama-rocm # for AMD
        #ollama-vulkan # as a GPU-generic fallback
        #ollama-cpu # for no hardware-acceleration backend
      ];
    })

    (lib.mkIf (cfg.gui.enable && cfg.gui.ollamaGui.enable) {
      home.packages = with pkgs; [
        alpaca

        # ──────────────────────────────────────────────────────────────────────
        # A self-hosted Next.js web app (its own long-running web service, not
        # a native window). E.g., For browser-based multi-device access to
        # local models. It's a different operational shape from `alpaca` — more
        # infra (a port, a running Node service).
        # ──────────────────────────────────────────────────────────────────────
        #nextjs-ollama-llm-ui
      ];
    })
  ];
}
