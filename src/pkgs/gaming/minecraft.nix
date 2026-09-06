# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/gaming/minecraft.nix
# ──────────────────────────────────────────────────────────────────────────────
#
# Minecraft via Prism Launcher — the recommended open-source launcher on NixOS.
#
# LAUNCHER CHOICE:
#   Prism Launcher (default) — open source MultiMC fork, best general choice.
#   ATLauncher (alternative)  — modpack-focused, also in nixpkgs.
#   TLauncher               —  Unofficial, "privacy-invasive".
#
# ──────────────────────────────────────────────────────────────────────────────
# WHY PRISM
#   Prism Launcher is fully open source (MultiMC fork), in nixpkgs, and
#   explicitly recommended by the NixOS wiki.
#
#   It handles multiple instances, all mod loaders (Fabric, Forge, Quilt,
#   NeoForge), and CurseForge/Modrinth integration cleanly.
#
# ──────────────────────────────────────────────────────────────────────────────
# WHY NOT ATLAUNCHER:
#   ATLauncher is also fine and in nixpkgs (pkgs.atlauncher), but it's
#   more modpack-oriented. Prism is the better "general-purpose" choice.
#   Swap the package below if you prefer ATLauncher.
#
# ──────────────────────────────────────────────────────────────────────────────
# JAVA STRATEGY:
#   Prism uses system Java by defult.Multiple Java versions can be added
#   via the prismlauncher.override mechanism (see below).
#
#   We override to provide all three generations so Prism can auto-select per
#   instance without downloading its own JREs.
#   Different MinceCraft versions require diff java:
#     Java  8  → MC < 1.17
#     Java 17  → MC 1.18–1.20.4
#     Java 21  → MC 1.20.5+ (current)
#
# ──────────────────────────────────────────────────────────────────────────────
# INSTANCE STORAGE:
#   Prism stores instances in ~/.local/share/PrismLauncher/instances/.
#
#   Point Prism's instance directory at the local Minecraft path so instances
#   live alongside other game data under ${cypherOsConstants.backupRoot}/GAMING/
#
#   Settings > Launcher > Folders > Instance Folder →
#     ${cypherOsConstants.backupRoot}/GAMING/local/Minecraft/
#
# ──────────────────────────────────────────────────────────────────────────────
# FIRST-RUN: Launch Prism — add your Microsoft/Mojang account
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.gaming;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.minecraft.enable) {
    home.packages = [
      # ────────────────────────────────────────────────────────────────────────
      # OPTION A: PRISM LAUNCHER
      # ────────────────────────────────────────────────────────────────────────

      # ────────────────────────────────────────────────────────────────────────
      # Prism with extra Java runtimes declared explicitly — avoids Prism's
      # "download Java for me" behavior which conflicts with Nix store paths.
      # ────────────────────────────────────────────────────────────────────────
      (pkgs.prismlauncher.override {
        jdks = with pkgs; [
          # ────────────────────────────────────────────────────────────────────
          # Java 21 — MC 1.20.5+ (current recommended)
          # ────────────────────────────────────────────────────────────────────
          temurin-bin-21

          # ────────────────────────────────────────────────────────────────────
          # Java 17 — MC 1.18–1.20.4
          # ────────────────────────────────────────────────────────────────────
          temurin-bin-17

          # ────────────────────────────────────────────────────────────────────
          # Java 8 — legacy MC versions < 1.17
          # ────────────────────────────────────────────────────────────────────
          temurin-bin-8
        ];
      })

      # ────────────────────────────────────────────────────────────────────────
      # OPTION B: ATLAUNCHER (i.e., for modpack-centric workflow)
      # ────────────────────────────────────────────────────────────────────────

      # ────────────────────────────────────────────────────────────────────────
      # Uncomment this block and comment out Option A to use ATLauncher instead.
      # Note: ATLauncher tries to install its own JRE into
      #   ~/.local/share/ATLauncher/runtimes/
      #
      # Override this in ATLauncher: Settings > Java/Minecraft > Java Path →
      #   point to a Nix store Java binary (find it with: which java)
      #   and disable "Use Java Provided By Minecraft".
      # ────────────────────────────────────────────────────────────────────────
      #pkgs.atlauncher
    ];
  };
}

# ──────────────────────────────────────────────────────────────────────────────
# RFC: Ensure ~/.local/share/PrismLauncher/instances/ is properly backed up
# ──────────────────────────────────────────────────────────────────────────────
# Point instance storage at the BTRFS shared data path
#    (Settings > Launcher > Folders > Instance Folder)
# ──────────────────────────────────────────────────────────────────────────────
