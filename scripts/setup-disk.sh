#!/usr/bin/env bash
set -euo pipefail

DISK="/dev/sda"
BTRFS_PART="${DISK}1"
EFI_PART="${DISK}2"

MNT="/mnt"

# DBMS subvolumes — top-level siblings of @home/@nix-store/@swap, deliberately
# NOT nested inside @home. See docs/project/guide_btrfs_snapshots.md for why: nesting
# a subvolume inside an already-mounted subvolume depends on systemd mount
# ordering that NixOS does not reliably guarantee (nixpkgs#217179). Siblings
# off subvolid=5 sidestep that failure class entirely.
#
# Provisioned now even for DBs not yet running as services (Meilisearch,
# MongoDB, Neo4j) so enabling them later never requires touching the disk
# layout again — only the Nix service config.
DBMS_NAMES=(postgres mariadb valkey meilisearch mongo neo4j)

echo "== Mounting BTRFS root =="
mount -t btrfs -o subvolid=5 "$BTRFS_PART" "$MNT"

echo "== Creating subvolumes =="
btrfs subvolume create $MNT/@nixos-root
btrfs subvolume create $MNT/@home
btrfs subvolume create $MNT/@nix-store
btrfs subvolume create $MNT/@swap

echo "== Creating DBMS subvolumes =="
for name in "${DBMS_NAMES[@]}"; do
  btrfs subvolume create "$MNT/@dbms_${name}"
done

echo "== Preparing swap subvolume =="
chattr +C $MNT/@swap

echo "== Creating swapfile =="
fallocate -l 10G $MNT/@swap/swapfile
chmod 600 $MNT/@swap/swapfile
mkswap $MNT/@swap/swapfile

echo "== Unmounting base mount =="
umount $MNT

echo "== Mounting final layout =="

mount -t btrfs -o subvol=@nixos-root,compress=zstd:3,noatime "$BTRFS_PART" "$MNT"

mkdir -p $MNT/{boot,home,cypher-whisperer/DATA,nix,swap,dbms}
for name in "${DBMS_NAMES[@]}"; do
  mkdir -p "$MNT/dbms/${name}"
done

mount -t vfat "$EFI_PART" $MNT/boot

mount -t btrfs -o subvol=@home,compress=zstd:3,noatime "$BTRFS_PART" $MNT/home
mount -t btrfs -o subvol=@nix-store,compress=zstd:3,noatime "$BTRFS_PART" $MNT/nix
mount -t btrfs -o subvol=@swap,noatime "$BTRFS_PART" $MNT/swap

echo "== Mounting DBMS subvolumes =="
for name in "${DBMS_NAMES[@]}"; do
  mount -t btrfs -o "subvol=@dbms_${name},compress=zstd:3,noatime" "$BTRFS_PART" "$MNT/dbms/${name}"
done

echo "== Activating swap =="
swapon $MNT/swap/swapfile

echo "== Done =="
echo "Note: dbms/* directories are root-owned at this point (0755)."
echo "Ownership per-database (postgres:postgres, mysql:mysql, etc.) is"
echo "handled declaratively by systemd.tmpfiles.rules at first boot — see"
echo "modules/devops/dbmss.nix. Do not chown these by hand; let the flake do it so it stays reproducible."
