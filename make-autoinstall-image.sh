#!/bin/bash

set -euxo pipefail

[[ ! -x "$(command -v xorriso)" ]] && die "Please install the 'xorriso' package."
[[ ! -x "$(command -v wget)" ]] && die "Please install the 'wget' package."
[[ ! -x "$(command -v apt-rdepends)" ]] && die "Please install the 'apt-rdepends' package."

# Retrieve the server ISO, if we don't have it already.
if [ ! -f ubuntu-22.04.1-live-server-amd64.iso ]; then
    wget --progress=dot -e dotbytes=10M https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso
fi

# Also retrieve the desktop ISO, if we don't have it already.
if [ ! -f ubuntu-22.04.1-desktop-amd64.iso ]; then
    wget --progress=dot -e dotbytes=10M https://releases.ubuntu.com/22.04/ubuntu-22.04.1-desktop-amd64.iso
fi

# Extract the desktop filesystem, if we haven't done so already:
if [ ! -f desktop-casper/filesystem.squashfs ]; then
    mkdir desktop-casper
    xorriso -osirrox on -indev "ubuntu-22.04.1-desktop-amd64.iso" -extract /casper/ desktop-casper/
    chmod -R +w desktop-casper
    touch meta-data
fi

# And extract the entire server ISO, if we haven't done so already.
if [ ! -f server-iso-extracted/.disk/info ]; then
    mkdir server-iso-extracted
    xorriso -osirrox on -indev "ubuntu-22.04.1-live-server-amd64.iso" -extract / server-iso-extracted
    chmod -R +w server-iso-extracted
    cp server-iso-extracted/casper/ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs unmodified-ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs
fi

sudo ./modify-desktop-squashfs.sh desktop-casper/filesystem.squashfs desktop-squashfs-modifications.sh
sudo ./modify-server-squashfs.sh

date -u +"Ubuntu 22.04 autoinstall, build %Y-%m-%dT%H:%M:%SZ" > disk-info.txt

echo "export WIFI_SSID=\"$WIFI_SSID\"" > server-iso-extracted/wifi-secrets
echo "export WIFI_PASSWORD=\"$WIFI_PASSWORD\"" >> server-iso-extracted/wifi-secrets

mkdir -p server-iso-extracted/nocloud
cp meta-data server-iso-extracted/nocloud/meta-data
cp user-data server-iso-extracted/nocloud/user-data
cp grub.cfg server-iso-extracted/boot/grub/grub.cfg
cp install-sources.yaml server-iso-extracted/casper/
cp disk-info.txt server-iso-extracted/.disk/info
cp desktop-casper/filesystem.manifest server-iso-extracted/casper/ubuntu-desktop.manifest
cp desktop-casper/filesystem.size server-iso-extracted/casper/ubuntu-desktop.size
cp desktop-casper/filesystem-modified.squashfs server-iso-extracted/casper/ubuntu-desktop.squashfs
cp modified-ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs server-iso-extracted/casper/ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs
cp attempt-wifi-connection.sh server-iso-extracted/
cp setup-secureboot-mok.sh server-iso-extracted/
cp sample.ogg server-iso-extracted/

# reconstruct md5sum.txt
#egrep -v '(boot/grub/grub.cfg|casper/install-sources.yaml|.disk/info)' server-md5sum.txt > md5sum.txt
cd server-iso-extracted
find ./dists ./.disk ./pool ./casper ./boot -type f -print0 | xargs -0 md5sum > md5sum.txt
cd ..

# Parameters found with 'xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs'

xorriso -joliet on -as mkisofs \
    -V 'Ubuntu 22.04 autoinstall' \
    --modification-date="$(date -u +'%Y%m%d%H%M%S00')" \
    --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'ubuntu-22.04.1-live-server-amd64.iso' \
    --protective-msdos-label \
    -partition_cyl_align off \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:2871452d-2879947d::'ubuntu-22.04.1-live-server-amd64.iso' \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2_start_717863s_size_8496d:all::' \
    -no-emul-boot \
    -boot-load-size 8496 \
    -isohybrid-gpt-basdat \
    -V "Ubuntu 22.04.1 autoinstall" \
    -o ubuntu-22.04.1-frankeninstaller.iso \
    server-iso-extracted/


if [ "$#" -gt 0 ] && [ "$1" == 'startvm' ]; then
  vboxmanage storageattach autoinstall-test --storagectl IDE --port 0 --device 0 --type dvddrive --medium ubuntu-22.04.1-frankeninstaller.iso; vboxmanage startvm autoinstall-test
fi

