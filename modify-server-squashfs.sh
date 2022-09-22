#!/bin/bash

set -euxo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Must be run as root."
    exit 2
fi

if ischroot; then
  echo "This script is intended to run outside a chroot. It creates a chroot."
  exit 3
fi

INPUT_SQUASHFS=unmodified-ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs
OUTPUT_SQUASHFS=modified-ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs
MOD_SCRIPT=server-squashfs-modifications.sh
MOD_SCRIPT_BASE=$(basename "$MOD_SCRIPT")

rm "$OUTPUT_SQUASHFS" || true
mkdir -p layers/a layers/b layers/c layers/work squashfs-root

unsquashfs -d layers/upper "$INPUT_SQUASHFS"

mount -rt squashfs -o loop,nodev,noexec server-iso-extracted/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs layers/a
mount -rt squashfs -o loop,nodev,noexec server-iso-extracted/casper/ubuntu-server-minimal.ubuntu-server.squashfs layers/b
mount -rt squashfs -o loop,nodev,noexec server-iso-extracted/casper/ubuntu-server-minimal.squashfs layers/c

sudo mount -t overlay overlay -o lowerdir=layers/a:layers/b:layers/c,upperdir=layers/upper,workdir=layers/work squashfs-root

mount --bind /etc/resolv.conf squashfs-root/etc/resolv.conf
mount -t proc none squashfs-root/proc
mount -t sysfs none squashfs-root/sys
mount -t devpts none squashfs-root/dev/pts

cp $MOD_SCRIPT squashfs-root/tmp

chroot squashfs-root "/tmp/$MOD_SCRIPT_BASE"

umount squashfs-root/proc || umount -lf squashfs-root/proc
umount squashfs-root/sys
umount squashfs-root/dev/pts
umount squashfs-root/etc/resolv.conf

rm "squashfs-root/tmp/$MOD_SCRIPT_BASE" || true
umount squashfs-root layers/a layers/b layers/c

mksquashfs layers/upper "$OUTPUT_SQUASHFS" -comp xz
chown "$SUDO_UID:$SUDO_GID" "$OUTPUT_SQUASHFS"

rm -rf squashfs-root layers

exit 0

