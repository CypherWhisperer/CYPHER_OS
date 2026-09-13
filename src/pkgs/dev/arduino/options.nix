# ──────────────────────────────────────────────────────────────────────────────
# src/dev/arduino/options.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  ...
}:
{
  options.cypher-os.pkgs.dev.arduino = {
    enable = lib.mkEnableOption ''
      Arduino / IoT development environment.
      Enables the full stack: arduino-cli, arduino-language-server,
      clangd, serial port group access, and udev rules.
      Toggle sub-options below to include the IDE or OTA tooling.
    '';

    ide.enable = lib.mkEnableOption ''
      Arduino IDE 2.x (pkgs.arduino-ide).
      The official Electron-based GUI — useful for board/library
      management, Serial Monitor with timestamps, and uni lab
      compatibility. Not required for CLI + Neovim / VSCode workflows.
    '';

    ota.enable = lib.mkEnableOption ''
      OTA (Over-The-Air) upload tooling (pkgs.arduinoOTA). Relevant with
      WiFi-capable boards (ESP8266, ESP32).
    '';

    # ──────────────────────────────────────────────────────────────────────────
    # The board Fully Qualified Board Name (FQBN) consumed by:
    #   - arduino-language-server (-fqbn flag → LSP board awareness)
    #   - ZSH aliases (ard-build, ard-upload) via interpolation in zsh.nix
    #
    # Find your board's FQBN after installing its core:
    #   arduino-cli board listall | grep -i <board-name>
    #
    # Common values:
    #   "arduino:avr:uno"           → Arduino Uno  (most common starter board)
    #   "arduino:avr:nano"          → Arduino Nano
    #   "arduino:avr:mega"          → Arduino Mega
    #   "esp32:esp32:esp32"         → generic ESP32 (requires esp32:esp32 core)
    #   "esp8266:esp8266:nodemcuv2" → NodeMCU v2 (requires esp8266:esp8266 core)
    #
    # Change this accordingly; rebuild to propagate the new value to all
    # consumers (LSP cmd args, shell aliases).
    # ──────────────────────────────────────────────────────────────────────────
    fqbn = lib.mkOption {
      type = lib.types.str;
      default = "arduino:avr:uno";
      description = ''
        Fully Qualified Board Name for the target board.
        Propagated to arduino-language-server and ZSH build/upload aliases.
        Run `arduino-cli board listall` to find the correct value.
      '';
    };
  };
}
