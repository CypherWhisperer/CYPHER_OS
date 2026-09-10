# ──────────────────────────────────────────────────────────────────────────────
# src/system/sound.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # SOUND
  # ────────────────────────────────────────────────────────────────────────────
  # PipeWire is the modern audio/video server. It handles both audio (replacing
  # PulseAudio) and screen capture (replacing PulseAudio's monitor sources and
  # the older JACK ecosystem).
  #
  # sound.enable = false: disables the legacy ALSA-only sound config. Required
  # when using PipeWire — they conflict if both are active.
  #
  # wireplumber is the session manager that routes audio streams between apps
  # and hardware via PipeWire. Think of PipeWire as the router and WirePlumber
  # as the traffic controller.
  # ────────────────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false; # PipeWire replaces PulseAudio

  services.pipewire = {
    enable = true;
    alsa.enable = true; # ALSA compatibility layer
    alsa.support32Bit = true; # 32-bit ALSA support (needed for Steam/Wine)
    pulse.enable = true; # PulseAudio compatibility layer
    wireplumber.enable = true;
  };
}
