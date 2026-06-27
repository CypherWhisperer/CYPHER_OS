{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.cypher-os.apps.enable && config.cypher-os.apps.productivity.enable) {

    cypher-os.apps.productivity.claude.enable = lib.mkDefault true;
    cypher-os.apps.productivity.obsidian.enable = lib.mkDefault true;
    cypher-os.apps.productivity.penpot.enable = lib.mkDefault true;

    # Installing the rest of productivity applications
    home.packages = with pkgs; [
      # ── System Design ────────────────────────────────────────────────────────
      drawio
      staruml

      # ── Creative Suite ───────────────────────────────────────────────────────
      #houdini
      gimp
      inkscape
      blender
      krita
      kdePackages.kdenlive
      audacity
      figma-agent

      # ── Media ────────────────────────────────────────────────────────────────
      vlc
      spotify
      clapper

      # ── Communication ────────────────────────────────────────────────────────
      discord
      # Electron wrapper around Whatsapp: UI a bit off offset a bit down, due to electron headerbar
      # whatsapp-electron

      # WhatsApp for Mac: failed due to target - darwin
      # whatsapp-for-mac

      # WhatsApp for Linux: Refused build due t0 lack of maintenance
      # whatsapp-for-linux

      # Karere: Native GTK4 WhatsApp client. There is an issue with Plasma 6 not rendereing the Login QR code
      karere
      whatsapp-chat-exporter # WhatsApp database parser
      signal-desktop
      telegram-desktop

      # ── Workflow and Automation ──────────────────────────────────────────────
      #n8n # now handled by modules/devops/n8n.nix
    ];
  };
}
