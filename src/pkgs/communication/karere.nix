# ──────────────────────────────────────────────────────────────────────────────
# src/pkgs/communication/karere.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.cypher-os.pkgs.communication;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf (cfg.enable && cfg.karere.enable) {
    home.packages = with pkgs; [
      # ────────────────────────────────────────────────────────────────────────
      # Electron wrapper around Whatsapp: UI a bit off; offset a bit down
      # (i.e., to compensate for electron's headbar)
      # ────────────────────────────────────────────────────────────────────────
      #whatsapp-electron

      # ────────────────────────────────────────────────────────────────────────
      # WhatsApp for Mac: failed due to target - darwin
      # ────────────────────────────────────────────────────────────────────────
      #whatsapp-for-mac

      # ────────────────────────────────────────────────────────────────────────
      # WhatsApp for Linux: Refused build due t0 lack of maintenance
      # ────────────────────────────────────────────────────────────────────────
      #whatsapp-for-linux

      # ────────────────────────────────────────────────────────────────────────
      # Karere: Native GTK4 WhatsApp client. There is an issue with Plasma 6 not
      # rendereing the Login QR code
      # ────────────────────────────────────────────────────────────────────────
      karere

      #whatsapp-chat-exporter # WhatsApp database parser
    ];
  };
}
