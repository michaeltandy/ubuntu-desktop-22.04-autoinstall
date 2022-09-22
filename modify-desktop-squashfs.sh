#!/bin/bash

set -euxo pipefail

if [ "$#" -ne 2 ] || [ "${1: -9}" != '.squashfs' ] || [ "${2: -3}" != '.sh' ]; then
    echo "Usage: $0 tomodify.squashfs modscript.sh"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Must be run as root."
    exit 2
fi

if ischroot; then
  echo "This script is intended to run outside a chroot. It creates a chroot."
  exit 3
fi

INPUT_SQUASHFS=$1
OUTPUT_SQUASHFS="${INPUT_SQUASHFS%'.squashfs'}-modified.squashfs"
MOD_SCRIPT=$2
MOD_SCRIPT_BASE=$(basename "$MOD_SCRIPT")

rm "$OUTPUT_SQUASHFS" || true

unsquashfs "$INPUT_SQUASHFS"

#mount -o bind /run/ squashfs-root/run
#mount --bind /dev/ squashfs-root/dev
mount --bind /etc/resolv.conf squashfs-root/etc/resolv.conf
mount -t proc none squashfs-root/proc
mount -t sysfs none squashfs-root/sys
mount -t devpts none squashfs-root/dev/pts

cp $MOD_SCRIPT squashfs-root/tmp/

chroot squashfs-root "/tmp/$MOD_SCRIPT_BASE"

umount squashfs-root/proc || umount -lf squashfs-root/proc
umount squashfs-root/sys
umount squashfs-root/dev/pts
umount squashfs-root/etc/resolv.conf
#umount squashfs-root/dev
#umount squashfs-root/run

rm "squashfs-root/tmp/$MOD_SCRIPT_BASE" || true

mksquashfs squashfs-root "$OUTPUT_SQUASHFS" -comp xz
chown "$SUDO_UID:$SUDO_GID" "$OUTPUT_SQUASHFS"

rm -rf squashfs-root

exit 0


# $ unsquashfs -s desktop-casper/filesystem.squashfs 
# Found a valid SQUASHFS 4:0 superblock on desktop-casper/filesystem.squashfs.
# Creation or last append time Wed Aug 10 14:29:18 2022
# Filesystem size 2288187623 bytes (2234558.23 Kbytes / 2182.19 Mbytes)
# Compression xz
# Block size 131072
# Filesystem is exportable via NFS
# Inodes are compressed
# Data is compressed
# Uids/Gids (Id table) are compressed
# Fragments are compressed
# Always-use-fragments option is not specified
# Xattrs are compressed
# Duplicates are removed
# Number of fragments 11136
# Number of inodes 220933
# Number of ids 36
# Number of xattr ids 2

