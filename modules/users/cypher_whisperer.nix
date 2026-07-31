{ pkgs, ... }:

{
  # ─────────────────────────────────────────────────────────────────────────────
  # USER ACCOUNT
  # ─────────────────────────────────────────────────────────────────────────────
  # This is the canonical user declaration for cypher_whisperer on NixOS.
  # The uid = 1000 is the universal truth across the CypherOS fleet — every OS
  # recognises this user by UID number, not by username string. File ownership
  # on shared BTRFS subvolumes resolves correctly because UID 1000 is consistent.
  #
  # isNormalUser = true: creates a home directory, adds the user to the
  # 'users' group, and enables login. (As opposed to a system user.)
  #
  # extraGroups: the groups that give this user elevated access to hardware
  # and services. Each group is explained inline.
  users.users.cypher_whisperer = {
    isNormalUser = true;
    uid = 1000;
    description = "Cypher Whisperer";
    home = "/home/cypher-whisperer";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # sudo access
      "networkmanager" # manage network connections without sudo
      "audio" # direct audio device access (belt-and-suspenders with PipeWire)
      "video" # GPU/video device access
      "input" # input device access (needed for some Wayland compositors)
      "disk" # disk operations, such as using ventoy
      "adbusers" # android development and emulation with adb
      "libvirtd"
      "kvm" # Virtualization with KVM and qemu
    ];
  };

  # mutableUsers = false would make NixOS the sole authority on users —
  # passwd and adduser commands would be ignored. We'll Leave it true (the default)
  # for now since we may want to change passwords interactively. Revisit in
  # the hardening phase.
  # users.mutableUsers = false;

  # ─────────────────────────────────────────────────────────────────────────────
  # USER AVATAR (AccountsService)
  # ─────────────────────────────────────────────────────────────────────────────
  # AccountsService is the D-Bus daemon that GDM and the lock screen use to
  # display the user tile (name + avatar). It reads from a root-owned system path that
  # home.file cannot touch. An activationScript runs as root
  # during nixos-rebuild switch, so it can write there.
  #
  # The source path references the asset co-located with this flake — hermetic,
  # no manual copying needed.
  system.activationScripts.userAvatar = {
    text = ''
          install -Dm644 ${../../modules/de/assets/images/default-gnome-avatar.jpg} \
            /var/lib/AccountsService/icons/cypher_whisperer
          # AccountsService also needs a config file pointing at the icon
          mkdir -p /var/lib/AccountsService/users
          cat > /var/lib/AccountsService/users/cypher_whisperer <<EOF
      [User]
      Icon=/var/lib/AccountsService/icons/cypher_whisperer
      EOF
    '';
  };
}
