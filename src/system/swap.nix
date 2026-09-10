# ──────────────────────────────────────────────────────────────────────────────
# src/system/swap.nix
# ──────────────────────────────────────────────────────────────────────────────

{
  ...
}:
{
  # ────────────────────────────────────────────────────────────────────────────
  # SWAP
  # ────────────────────────────────────────────────────────────────────────────
  # The @swap BTRFS subvolume is mounted at /swap
  # (declared in hardware-configuration.nix). The swapfile was created during
  # install (fallocate -l 10G + mkswap). Declaring it here makes NixOS activate
  # it at boot via systemd.
  #
  # BTRFS swapfiles have one hard requirement: the file must live on a subvolume
  # with Copy-on-Write disabled (chattr +C). This is handled via the disk setup
  # bash scripts on @swap — so this is safe.
  # ────────────────────────────────────────────────────────────────────────────
  swapDevices = [
    {
      device = "/swap/swapfile";
      # ────────────────────────────────────────────────────────────────────────
      # size is informational here — the file is already sized at 10G on disk,
      # courtesy of the disk setup script. NixOS won't resize it; it just
      # activates it.
      # ────────────────────────────────────────────────────────────────────────
    }
  ];
}
