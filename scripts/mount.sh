#!/bin/bash

set -euo pipefail

DISK="/dev/sda"
BTRFS_PART="${DISK}1"
EFI_PART="${DISK}2"

MNT="/mnt"

DBMS_NAMES=(postgres mariadb valkey meilisearch mongo neo4j)

echo "== Mounting final layout =="

mount -t btrfs -o subvol=@nixos-root,compress=zstd:3,noatime "$BTRFS_PART" "$MNT"

mount -t vfat "$EFI_PART" $MNT/boot

mount -t btrfs -o subvol=@home,compress=zstd:3,noatime "$BTRFS_PART" $MNT/home
#mount -t btrfs -o subvol=@data,compress=zstd:3,noatime "$BTRFS_PART" $MNT/cypher-whisperer/DATA
# i.e, in the first CypherOS installation, an incident occured where in my own words,
# the system "tweaked"; In my own understanding, the system might have lost somewhat
# of a link to the actual data. Here's why; after the next build:
#  1. The directory ~/DATA (where the @data subvolume was supposed to be mounted) was empty
#  2. This at first - to me - seemed like a total data loss.
#  3. After a diagnosis session (involving booting into live ISO environments - BlendOS)
#     I discovered that the data was actually present (sitting on the disk) but somehow
#     the subvolume lost the link to it during the/some build process or something.
#  4. That prompted me to treat having a subvolume within another (i.e @data within @home )
#     as high stake and somewhat non-{deterministic,predictable} and my solution was to
#     drop the @data subvolume and instead have ~/DATA as a plain directory.
#
# ROOT CAUSE (confirmed, see nixpkgs#217179): systemd does not reliably honor mount
# ordering for a subvolume nested inside an already-mounted subvolume. @data was
# mounted *inside* @home, so its mount unit's ordering relative to @home's own mount
# unit wasn't guaranteed — a race or failed mount left ~/DATA resolving to @home's own
# (empty) directory instead. Data wasn't lost, it was orphaned. This is exactly why the
# DBMS subvolumes below are top-level siblings of @home/@nix-store/@swap, mounted
# directly off subvolid=5 — never nested inside another mounted subvolume.

mount -t btrfs -o subvol=@nix-store,compress=zstd:3,noatime "$BTRFS_PART" $MNT/nix
mount -t btrfs -o subvol=@swap,noatime "$BTRFS_PART" $MNT/swap

echo "== Mounting DBMS subvolumes (top-level siblings, not nested) =="
for name in "${DBMS_NAMES[@]}"; do
  mkdir -p "$MNT/dbms/${name}"
  mount -t btrfs -o "subvol=@dbms_${name},compress=zstd:3,noatime" "$BTRFS_PART" "$MNT/dbms/${name}"
done

echo "== Activating swap =="
swapon $MNT/swap/swapfile

echo "== Done =="
