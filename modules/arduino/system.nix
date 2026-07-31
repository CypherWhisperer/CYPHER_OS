# modules/arduino/system.nix
#
# NixOS-context configuration for the Arduino / IoT subsystem.
#
# WHAT THIS FILE OWNS:
#   - System-level package installation (arduino-cli, arduino-ide, arduinoOTA)
#   - udev rules (via services.udev.packages)
#   - Serial port group membership (dialout, uucp, lock)
#
# ── WHY arduino-cli IS INSTALLED AT SYSTEM LEVEL ────────────────────────────
#   arduino-cli ships its own udev rules package. NixOS merges udev rules by
#   scanning the /lib/udev/rules.d directories of packages listed in
#   services.udev.packages. For that merge to see the arduino-cli rules, the
#   package must be reachable at system activation time — which means it must
#   appear in environment.systemPackages or a similar system-level derivation.
#   It is also installed in hm.nix (user PATH) for day-to-day CLI use;
#   the duplication is intentional and harmless — Nix deduplicates the store path.
#
# ── WHY NOT services.udev.extraRules ────────────────────────────────────────
#   There is a known NixOS regression (tracked in nixpkgs#308681) where rules
#   written via services.udev.extraRules land in 99-local.rules. The priority
#   number 99 is too late in udev's processing order for TAG+="uaccess" to
#   take effect, causing silent permission failures on USB serial devices.
#   Using services.udev.packages instead lets the arduino-cli package's own
#   rule file ship at its correct priority (typically 60-*), sidestepping
#   the regression entirely.
#
# ── POST-SWITCH IMPERATIVE STEPS ────────────────────────────────────────────
#   The following steps must be performed manually after the first
#   `sudo nixos-rebuild switch`. They are imperative because they download
#   board toolchains from the internet at runtime — Nix cannot hash-pin
#   them at evaluation time without a dedicated fetcher derivation per board.
#
#   1. Update the arduino-cli package index (fetches board index JSON):
#        arduino-cli core update-index
#
#   2. Install the AVR core (covers Uno, Nano, Mega — most starter boards):
#        arduino-cli core install arduino:avr
#
#      If you use ESP32 or ESP8266, also add the board manager URL
#      to the arduino-cli config (see hm.nix → xdg.configFile arduino-cli.yaml,
#      the additional_urls list), then rebuild, then install the core:
#        arduino-cli core install esp32:esp32
#        arduino-cli core install esp8266:esp8266
#
#   3. Verify your board is detected (plug it in first):
#        arduino-cli board list
#
#   4. Re-login (or reboot) after this switch for the dialout group to take
#      effect. Until you do, /dev/ttyACM0 and /dev/ttyUSB0 will return
#      "permission denied" regardless of the group declaration below.
#      Temporary workaround without a full re-login:
#        newgrp dialout
#
# ── WHY TOOLCHAIN INSTALLS ARE NOT NIX-IFIABLE ──────────────────────────────
#   arduino-cli downloads compiler toolchains (avr-gcc, avrdude, etc.) from
#   Arduino's CDN as pre-compiled tarballs. These binaries have their dynamic
#   linker path hardcoded to /lib64/ld-linux-x86-64.so.2 — a path NixOS does
#   not provide at the root filesystem level. The nixpkgs arduino-cli derivation
#   wraps the binary in a buildFHSEnv chroot so downloaded toolchains can run,
#   but the downloads themselves happen imperatively at first use. There is a
#   community project (arduino-nix) that Nix-ifies this by pinning each core
#   as a fixed-output derivation, but it requires per-board maintenance and is
#   not yet in nixpkgs.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../profile/options.nix
    ./options.nix
  ];
  config = lib.mkIf (config.cypher-os.profile.desktop.enable && config.cypher-os.arduino.enable) {

    # ── System-level packages ──────────────────────────────────────────────────
    # arduino-cli: installed here for udev rule discovery (see note above).
    #   Conditionally included packages:
    #   - arduino-ide (pkgs.arduino-ide): Arduino IDE 2.x, Electron-based.
    #     Wraps itself in buildFHSEnv so downloaded board toolchains can run.
    #     Enabled via cypher-os.arduino.ide.enable.
    #   - arduinoOTA (pkgs.arduinoOTA): OTA upload tool for WiFi boards.
    #     Enabled via cypher-os.arduino.ota.enable — add when course reaches
    #     ESP8266 / ESP32 WiFi units.
    #
    # ── Ruled-out packages ────────────────────────────────────────────────────
    # pkgs.arduino (IDE 1.x, Java): superseded by arduino-ide (2.x). Skip.
    # pkgs.arduino-core / arduino-core-unwrapped: low-level AVR headers used
    #   internally by other derivations. Not needed directly.
    # pkgs.arduino-ci: CI test runner for Arduino library authors. Not needed
    #
    # pkgs.arduino-create-agent: browser-to-board bridge for Arduino Cloud IDE.
    #   Privacy concern (phone-home), and we're running a local stack. Skip.
    # pkgs.arduino-mk: Makefile-based build system. arduino-cli covers all
    #   the same ground with a better interface. Omitted.
    environment.systemPackages =
      with pkgs;
      [ arduino-cli ]
      ++ lib.optionals config.cypher-os.arduino.ide.enable [ arduino-ide ]
      ++ lib.optionals config.cypher-os.arduino.ota.enable [ arduinoOTA ];

    # ── udev rules ────────────────────────────────────────────────────────────
    # Merges arduino-cli's bundled udev rule file into the system rule set.
    # These rules cover CH340, CP2102, FTDI, and ATmega native-USB chips —
    # the serial adapters found on virtually all Arduino boards.
    # See the "WHY NOT services.udev.extraRules" note above for why this
    # approach is used instead of writing inline rules.
    services.udev.packages = [ pkgs.arduino-cli ];

    # ── Serial port access ─────────────────────────────────────────────────────
    # Arduino boards enumerate as:
    #   /dev/ttyACM* — boards with native USB (Uno R3, Leonardo, Mega, etc.)
    #   /dev/ttyUSB* — boards with CH340/FTDI USB-serial adapters (Nano clones)
    #
    # Both device classes are owned by the dialout group on Linux.
    # uucp and lock are legacy group names that some older tooling still checks;
    # including them costs nothing and prevents subtle upload failures.
    #
    # IMPORTANT: group membership only takes effect after a full re-login or
    # reboot. See the POST-SWITCH IMPERATIVE STEPS note above.
    users.users.cypher_whisperer = {
      extraGroups = [
        "dialout"
        "uucp"
        "lock"
      ];
    };
  };
}
