# ──────────────────────────────────────────────────────────────────────────────
# src/system/virtulisation/system.nix
# ──────────────────────────────────────────────────────────────────────────────
# NixOS module for virtualisation helpers: distrobox, winboat (Windows app
# compatibility), and Vagrant for declarative VM provisioning.
#
# ──────────────────────────────────────────────────────────────────────────────
# WHAT THIS FILE OWNS:
# ──────────────────────────────────────────────────────────────────────────────
# - distrobox (rootless container-based distro environments)
# - winboat (Bottles-style Wine app manager for running Windows software)
# - vagrant (declarative VM provisioning)
# - virt-viewer / spice-gtk (better display protocol for libvirt VMs)
#
# ──────────────────────────────────────────────────────────────────────────────
# DISTROBOX FIRST USE:
# ──────────────────────────────────────────────────────────────────────────────
# distrobox create --name ubuntu --image ubuntu:24.04
# distrobox enter ubuntu
#
# # You now have a full Ubuntu environment with access to your home directory.
# # Great for: running Debian/Ubuntu-specific tools on NixOS, testing package
# # behavior across distros, or using apt when you need it.
#
# ──────────────────────────────────────────────────────────────────────────────
# VAGRANT FIRST USE:
# ──────────────────────────────────────────────────────────────────────────────
# mkdir ~/vms/test && cd ~/vms/test
# vagrant init generic/ubuntu2404
# vagrant up
# vagrant ssh
# # Vagrant uses libvirt as the provider on Linux (via vagrant-libvirt plugin)
#
# ──────────────────────────────────────────────────────────────────────────────
# VERIFYING THE SETUP:
# ──────────────────────────────────────────────────────────────────────────────
# distrobox --version
# winboat --version  (or open via app launcher)
# vagrant --version
# ──────────────────────────────────────────────────────────────────────────────

{
  lib,
  pkgs,
  config,
  cypherOsProfile,
  ...
}:
let
  cfg = config.cypher-os.virtualisation.helpers;
in
{
  imports = [ ./options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cypherOsProfile == "desktop") {
      environment.systemPackages = with pkgs; [
        # ──────────────────────────────────────────────────────────────────────
        # virt-manager: the standard GUI for managing KVM/QEMU VMs on Linux.
        # ──────────────────────────────────────────────────────────────────────
        virt-manager

        # ──────────────────────────────────────────────────────────────────────
        # CLI tools for working with disk images (qemu-img, qemu-nbd, etc.)
        # ──────────────────────────────────────────────────────────────────────
        qemu-utils

        # ──────────────────────────────────────────────────────────────────────
        # ── distrobox:
        # ──────────────────────────────────────────────────────────────────────
        # Run any Linux distro's userspace inside a rootless container (uses
        # Podman or Docker under the hood). The container shares your home
        # directory and can even run GUI apps via XWayland.
        #
        # Instead ofbooting a full Arch or Debian, use distrobox to get that
        # distro's tools without rebooting. Best of both worlds.
        # Requires either podman (preferred, rootless) or docker to be enabled.
        # ──────────────────────────────────────────────────────────────────────
        distrobox

        # ──────────────────────────────────────────────────────────────────────
        # ── winboat:
        # ──────────────────────────────────────────────────────────────────────
        # A GUI application for managing Wine environments and running Windows
        # software. Creates isolated Wine "bottles" so different Windows apps
        # don't interfere with each other's Wine configurations.
        #
        # Similar in concept to Bottles (GNOME app) but with its own approach.
        # Good for: running Windows-only tools, games, or niche software.
        # Note: Wine compatibility varies per application. Expect trial and
        # error.
        # ──────────────────────────────────────────────────────────────────────
        winboat

        # ──────────────────────────────────────────────────────────────────────
        # ── vagrant:
        # ──────────────────────────────────────────────────────────────────────
        # Declarative VM provisioning. Describe a VM in a Vagrantfile; Vagrant
        # creates, starts, snapshots, and destroys it. Think "docker-compose
        # but for full VMs." Very common in DevOps learning resources.
        # On Linux, uses libvirt (KVM/QEMU) as the provider. Requires libvirtd
        # to be enabled.
        # Usage: vagrant init ubuntu/focal64 && vagrant up && vagrant ssh
        # ──────────────────────────────────────────────────────────────────────
        vagrant

        # ──────────────────────────────────────────────────────────────────────
        # ── virt-viewer:
        # ──────────────────────────────────────────────────────────────────────
        # Display client for virtual machines managed by libvirt. Connects via
        # theSPICE or VNC protocol and provides a proper display window for VMs.
        # virt-manager includes its own viewer, but standalone virt-viewer is
        # useful for quickly connecting to a specific VM by URI:
        #   virt-viewer --connect qemu:///system vm-name
        # ──────────────────────────────────────────────────────────────────────
        virt-viewer

        # ──────────────────────────────────────────────────────────────────────
        # ── spice-gtk:
        # ──────────────────────────────────────────────────────────────────────
        # GTK widget library implementing the SPICE protocol. Required by
        # virt-manager and virt-viewer to display SPICE-enabled VMs.
        # SPICE provides better performance than VNC: clipboard sharing, USB
        # redirection, dynamic resolution resizing, audio passthrough.
        # ──────────────────────────────────────────────────────────────────────
        spice-gtk

        # ──────────────────────────────────────────────────────────────────────
        # ── DEFERRED:
        # ──────────────────────────────────────────────────────────────────────

        # ──────────────────────────────────────────────────────────────────────
        # ── bottles:
        # ──────────────────────────────────────────────────────────────────────
        # alternative to winboat for managing Wine environments.
        # More actively maintained GNOME-style app. Compare with winboat and
        # keep whichever suits your workflow better.
        # ──────────────────────────────────────────────────────────────────────
        #bottles

        # ──────────────────────────────────────────────────────────────────────
        # ── wine:
        # ──────────────────────────────────────────────────────────────────────
        # the Wine compatibility layer itself. winboat/bottles manage Wine
        # environments and may pull in Wine as a dependency.
        # Installing standalone `wine` provides the bare `wine` CLI if needed;
        # without a GUI manager.
        # ──────────────────────────────────────────────────────────────────────
        #wine
      ];

      virtualisation.libvirtd = {
        # ──────────────────────────────────────────────────────────────────────
        # libvirt: the daemon virt-manager talks to
        # ──────────────────────────────────────────────────────────────────────
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm; # QEMU compiled specifically with KVM enabled.

          # ────────────────────────────────────────────────────────────────────
          # Alternatives (uncomment to override):
          # ────────────────────────────────────────────────────────────────────

          # ────────────────────────────────────────────────────────────────────
          # includes everything (all emulation targets, all frontends)
          # ────────────────────────────────────────────────────────────────────
          #qemu_full

          # ────────────────────────────────────────────────────────────────────
          # Xen hypervisor variant. If you're running a Xen setup.
          # ────────────────────────────────────────────────────────────────────
          #qemu_xen

          # ────────────────────────────────────────────────────────────────────
          # userspace emulation only; for cross-compilation,not VM hosting
          # ────────────────────────────────────────────────────────────────────
          #qemu-user

          # ────────────────────────────────────────────────────────────────────
          # Python bindings and QMP protocol tools. Only needed for scripting VM
          # management programmatically.
          # ────────────────────────────────────────────────────────────────────
          #qemu-python-utils
          #python313Packages.qemu
          #python313Packages.qemu-qmp
        };
      };
    })

    {
      assertions = [
        {
          assertion = cfg.enable -> (cypherOsProfile == "desktop");
          message = ''
            cypher-os.virtualisation.helpers.enble requires cypher-os.profile.active == "desktop".
          '';
        }
      ];
    }
  ];
}
