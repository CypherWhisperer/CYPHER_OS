# ──────────────────────────────────────────────────────────────────────────────
# src/users/cypher_whisperer.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  pkgs,
  config,
  cypherOsConstants,
  ...
}:
let
  cfg = config.cypher-os.shell;
  primaryShell = cypherOsConstants.primaryUserShell;

  # ────────────────────────────────────────────────────────────────────────────
  # "bash" is intentionally excluded from cypher-os.shell.* — it's the baseline,
  # not a toggle — so it short-circuits true here rather than being DIRECTLY
  # checked  (i.e., in the same way the other toggle-able options) against a
  # namespace  path that doesn't exist for it.
  # ────────────────────────────────────────────────────────────────────────────
  shellIsAvailable = primaryShell == "bash" || (cfg.enable && cfg.${primaryShell}.enable);
in
{
  # ────────────────────────────────────────────────────────────────────────────
  # USER ACCOUNT
  # ────────────────────────────────────────────────────────────────────────────
  # This is the canonical user declaration for cypher_whisperer on NixOS.
  # The uid = 1000 is the universal truth across the CypherOS fleet — every OS
  # recognises this user by UID number, not by username string.
  #
  # File ownership on shared BTRFS subvolumes resolves correctly because
  # UID 1000 is consistent.
  #
  # ────────────────────────────────────────────────────────────────────────────
  # isNormalUser = true: creates a home directory, adds the user to the
  # 'users' group, and enables login. (As opposed to a system user.)
  #
  # ────────────────────────────────────────────────────────────────────────────
  # extraGroups: the groups that give this user elevated access to hardware
  # and services. Each group is explained inline.
  # ────────────────────────────────────────────────────────────────────────────
  users.users.${cypherOsConstants.username} = {
    isNormalUser = true;
    uid = cypherOsConstants.userId;
    description = cypherOsConstants.displayName;
    home = cypherOsConstants.homeDirectory;

    # ──────────────────────────────────────────────────────────────────────────
    # NOTE: pkgs.${primaryShell} here only resolves correctly because each enum
    # string is spelled identically to its current nixpkgs attribute name.
    # ──────────────────────────────────────────────────────────────────────────
    shell = pkgs.${primaryShell};
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

  # ────────────────────────────────────────────────────────────────────────────
  # a false value for mutableUsers would make NixOS the sole authority on
  # users — passwd and adduser commands would be ignored.
  #
  # Left as the default true for now, e.g.,
  # for th ability to change passwords interactively.
  # ────────────────────────────────────────────────────────────────────────────
  # users.mutableUsers = false;
  # ────────────────────────────────────────────────────────────────────────────

  assertions = [
    {
      assertion = shellIsAvailable;
      message = ''
        cypher-os.constants.primaryUserShell is set to "${primaryShell}", but
        cypher-os.shell.enable && cypher-os.shell.${primaryShell}.enable
        aren't both true. Enable that shell, or set primaryUserShell to "bash".
      '';
    }
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # USER AVATAR (AccountsService)
  # ────────────────────────────────────────────────────────────────────────────
  # AccountsService is the D-Bus daemon that GDM and the lock screen use to
  # display the user tile (name + avatar).
  #
  # It reads from a root-owned system path that home.file cannot touch.
  # An activationScript runs as root during nixos-rebuild switch, so it can
  # write there.
  # ────────────────────────────────────────────────────────────────────────────
  system.activationScripts.userAvatar = {
    text = ''
          install -Dm644 ${cypherOsConstants.userAvatar} \
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
