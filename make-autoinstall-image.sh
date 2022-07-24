#!/bin/bash

set -euxo pipefail

[[ ! -x "$(command -v xorriso)" ]] && die "Please install the 'xorriso' package."
[[ ! -x "$(command -v wget)" ]] && die "Please install the 'wget' package."
[[ ! -x "$(command -v apt-rdepends)" ]] && die "Please install the 'apt-rdepends' package."

if [ ! -f ubuntu-22.04-live-server-amd64.iso ]; then
    wget https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
fi

if [ ! -f ubuntu-22.04-desktop-amd64.iso ]; then
    wget https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop-amd64.iso
fi

if [ ! -f desktop-casper/filesystem.squashfs ]; then
    mkdir desktop-casper
    xorriso -osirrox on -indev "ubuntu-22.04-live-server-amd64.iso" -extract md5sum.txt server-md5sum.txt
    xorriso -osirrox on -indev "ubuntu-22.04-desktop-amd64.iso" -extract /casper/ desktop-casper/ -extract md5sum.txt desktop-md5sum.txt
    touch meta-data
fi

if [ ! -f packages-to-install/linux-generic_*_amd64.deb ]; then
    mkdir packages-to-install
    cd packages-to-install
    apt-get download $(apt-rdepends linux-generic|egrep '^(linux-generic|linux-headers-generic|linux-headers|linux-image-|linux-modules-)')
    cd ..
fi

# reconstruct md5sum.txt
egrep -v '(boot/grub/grub.cfg|casper/install-sources.yaml)' server-md5sum.txt > md5sum.txt
egrep 'casper/(filesystem.manifest|filesystem.size|filesystem.squashfs|filesystem.squashfs.gpg)' desktop-md5sum.txt >> md5sum.txt

cp ubuntu-22.04-live-server-amd64.iso ubuntu-22.04-frankeninstaller.iso

xorriso -boot_image any keep \
        -dev ubuntu-22.04-frankeninstaller.iso \
        -map meta-data /nocloud/meta-data \
        -map user-data /nocloud/user-data \
        -map grub.cfg /boot/grub/grub.cfg \
        -map md5sum.txt /md5sum.txt \
        -map desktop-casper/filesystem.manifest /casper/ubuntu-desktop.manifest \
        -map desktop-casper/filesystem.size /casper/ubuntu-desktop.size \
        -map desktop-casper/filesystem.squashfs /casper/ubuntu-desktop.squashfs \
        -map desktop-casper/filesystem.squashfs.gpg /casper/ubuntu-desktop.squashfs.gpg \
        -map packages-to-install/ /packages-to-install/ \
        -map install-sources.yaml /casper/install-sources.yaml \
        -map packages-to-purge.txt /packages-to-purge.txt


#vboxmanage storageattach autoinstall-test --storagectl IDE --port 0 --device 0 --type dvddrive --medium ubuntu-22.04-frankeninstaller.iso
    

