# ──────────────────────────────────────────────────────────────────────────────
# src/dm/gdm/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# GDM (GNOME Display Manager) is the login screen. It handles session
# selection and hands off to either the GNOME Wayland or X11 session.
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.dm.gdm;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (cypherOsProfile == "desktop" && cfg.enable) {
      services.displayManager.gdm = {
        enable = true;
        # ──────────────────────────────────────────────────────────────────────
        # This option is no longer supported with GNOME 50. This came after a
        # flake update 2026-06-05.
        # wayland = true; # GDM falls back to X11.
        # ──────────────────────────────────────────────────────────────────────
      };
    })

    # ──────────────────────────────────────────────────────────────────────────
    # DEFAULTS CONFIGURATION.
    # ──────────────────────────────────────────────────────────────────────────
    {
      cypher-os.dm.gdm.enable = lib.mkDefault (cypherOsProfile == "desktop");
    }

    # ──────────────────────────────────────────────────────────────────────────
    # ASSERTIONS.
    # ──────────────────────────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion = cfg.enable -> cypherOsProfile == "desktop";
          message = ''
            cypher-os.dm.gdm.enable requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
# ──────────────────────────────────────────────────────────────────────────────
# RFC: ASSERTION
# ──────────────────────────────────────────────────────────────────────────────
# Assertion to ensure:
# 1. No 2 dms are installed at the same time
# 2. At least one is installed.
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# RFC: GDM BLURRED BACKGROUND
# ──────────────────────────────────────────────────────────────────────────────
# GDM runs its own isolated gnome-shell instance — user extensions (including
# blur-my-shell) never run there. The only way to set a GDM background is to
# patch the gnome-shell gresource file that GDM reads.
#
# Strategy (activation script, not overlay):
#   - Runs against the already-built gnome-shell binary — no source rebuild.
#   - Extracts the gresource, swaps the background image, recompiles it into
#     a writable system path that gdm reads first.
#   - Runs on every nixos-rebuild switch; idempotent.
#   - We write to /etc/gnome-shell-gdm-theme/ and point GDM at it via a
#     gnome-shell CSS override.
#
# PREREQUISITE: generate the blurred image once:
#  nix-shell -p imagemagick --run \
#  "convert src/de/assets/default-gnome-bg.jpg -blur 0x18 src/de/assets/default-gdm-bg.jpg"
# ──────────────────────────────────────────────────────────────────────────────
#system.activationScripts.gdmBackground = {
#  deps = [ "users" ];
#  text = let
#    gnomeShellGresource =
#      "${pkgs.gnome-shell}/share/gnome-shell/gnome-shell-theme.gresource";
#    blurredBg = ../assets/default-gdm-bg.jpg;
#    gresource = "${pkgs.glib.dev}/bin/gresource";
#    glib-compile = "${pkgs.glib}/bin/glib-compile-resources";
#  in ''
#    # Bail out gracefully if tools aren't present rather than failing activation
#    if [ ! -f ${gresource} ]; then
#      echo "gdmBackground: gresource not found, skipping" >&2
#      exit 0
#    fi

#    WORKDIR=$(mktemp -d)
#   trap "rm -rf $WORKDIR" EXIT

#    for r in $(${gresource} list ${gnomeShellGresource}); do
#      rel=''${r#/org/gnome/shell/}
#      mkdir -p "$WORKDIR/''${rel%/*}"
#      ${gresource} extract ${gnomeShellGresource} "$r" \
#        > "$WORKDIR/$rel"
#    done

#    cp ${blurredBg} "$WORKDIR/theme/noise-texture.png"

#    mkdir -p /etc/gnome-shell-gdm-theme
#    ${glib-compile} \
#      --target="/etc/gnome-shell-gdm-theme/gnome-shell-theme.gresource" \
#      --sourcedir="$WORKDIR" \
#      "$WORKDIR/gnome-shell-theme.gresource.xml"
#  '';
#};

# ──────────────────────────────────────────────────────────────────────────────
# Override the GDM gnome-shell gresource path via an environment variable
# injected into the GDM session.
# ──────────────────────────────────────────────────────────────────────────────
# NOTE:
# ──────────────────────────────────────────────────────────────────────────────
# Honest note: The GNOME_SHELL_THEME_DIR env var approach may or may not be
# respected depending on gnome-shell version — this is the part that's
# genuinely version-sensitive. If it doesn't take effect, the fallback is a
# symlink override:
#
# ln -sf /etc/gnome-shell-gdm-theme/gnome-shell-theme.gresource \
#   ${pkgs.gnome-shell}/share/gnome-shell/gnome-shell-theme.gresource
#
# but that writes into the store (read-only). The cleanest alternative at
# that point would be a services.xserver.displayManager.gdm.extraConfig-style
# approach or a bind mount.
# ──────────────────────────────────────────────────────────────────────────────
#systemd.services.gdm.environment = {
#  GNOME_SHELL_THEME_DIR = "/etc/gnome-shell-gdm-theme";
#};
