#!/bin/bash

set -euxo pipefail

if ! ischroot -t; then
  echo "This script is intended to run within a chroot, to modify a squashfs image."
  exit 1
fi

apt-get update
apt install -y mokutil efibootmgr network-manager tpm2-tools sox

echo "FallbackDNS=8.8.8.8" >> /etc/systemd/resolved.conf
echo "FallbackNTP=ntp.ubuntu.com" >> /etc/systemd/timesyncd.conf

# Clean up the image
apt clean
rm -rf /tmp/* ~/.bash_history /var/lib/apt/lists/*
rm /var/lib/dbus/machine-id || true
