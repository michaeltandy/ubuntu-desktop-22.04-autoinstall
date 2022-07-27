#!/bin/bash

set -euxo pipefail

[[ ! -x "$(command -v xorriso)" ]] && die "Please install the 'xorriso' package."
[[ ! -x "$(command -v wget)" ]] && die "Please install the 'wget' package."
[[ ! -x "$(command -v apt-rdepends)" ]] && die "Please install the 'apt-rdepends' package."

if [ ! -f ubuntu-22.04-live-server-amd64.iso ]; then
    wget --progress=dot -e dotbytes=10M https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
fi

if [ ! -f ubuntu-22.04-desktop-amd64.iso ]; then
    wget --progress=dot -e dotbytes=10M https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop-amd64.iso
fi

if [ ! -f desktop-casper/filesystem.squashfs ]; then
    mkdir desktop-casper
    #xorriso -osirrox on -indev "ubuntu-22.04-live-server-amd64.iso" -extract md5sum.txt server-md5sum.txt
    xorriso -osirrox on -indev "ubuntu-22.04-desktop-amd64.iso" -extract /casper/ desktop-casper/ -extract md5sum.txt desktop-md5sum.txt
    chmod -R +w desktop-casper
    touch meta-data
fi

if [ ! -f server-iso-extracted/.disk/info ]; then
    mkdir server-iso-extracted
    xorriso -osirrox on -indev "ubuntu-22.04-live-server-amd64.iso" -extract / server-iso-extracted
    chmod -R +w server-iso-extracted
    cp server-iso-extracted/md5sum.txt server-md5sum.txt
fi


if [ ! -f packages-to-install/linux-generic_*_amd64.deb ]; then
    mkdir packages-to-install
    cd packages-to-install
    apt-get download $(apt-rdepends linux-generic|egrep '^(linux-generic|linux-headers-generic|linux-headers|linux-image-|linux-modules-)')
    cd ..
fi

date -u +"Ubuntu 22.04 autoinstall, build %Y-%m-%dT%H:%M:%SZ" > disk-info.txt

# reconstruct md5sum.txt
egrep -v '(boot/grub/grub.cfg|casper/install-sources.yaml|.disk/info)' server-md5sum.txt > md5sum.txt
egrep 'casper/(filesystem.manifest|filesystem.size|filesystem.squashfs|filesystem.squashfs.gpg)' desktop-md5sum.txt >> md5sum.txt

mkdir -p server-iso-extracted/nocloud
cp meta-data server-iso-extracted/nocloud/meta-data
cp user-data server-iso-extracted/nocloud/user-data
cp grub.cfg server-iso-extracted/boot/grub/grub.cfg
cp md5sum.txt server-iso-extracted/md5sum.txt
cp disk-info.txt server-iso-extracted/.disk/info
cp desktop-casper/filesystem.manifest server-iso-extracted/casper/ubuntu-desktop.manifest
cp desktop-casper/filesystem.size server-iso-extracted/casper/ubuntu-desktop.size
cp desktop-casper/filesystem.squashfs server-iso-extracted/casper/ubuntu-desktop.squashfs
cp desktop-casper/filesystem.squashfs.gpg server-iso-extracted/casper/ubuntu-desktop.squashfs.gpg
cp -r packages-to-install/ server-iso-extracted/packages-to-install/
cp install-sources.yaml server-iso-extracted/casper/install-sources.yaml
cp packages-to-purge.txt server-iso-extracted/packages-to-purge.txt

# Parameters found with 'xorriso -indev ubuntu-22.04-live-server-amd64.iso -report_el_torito as_mkisofs'

xorriso -joliet on -as mkisofs \
    -V 'Ubuntu 22.04 autoinstall' \
    --modification-date="$(date -u +'%Y%m%d%H%M%S00')" \
    --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'ubuntu-22.04-live-server-amd64.iso' \
    --protective-msdos-label \
    -partition_cyl_align off \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:2855516d-2864011d::'ubuntu-22.04-live-server-amd64.iso' \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c '/boot.catalog' \
    -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2_start_713879s_size_8496d:all::' \
    -no-emul-boot \
    -boot-load-size 8496 \
    -isohybrid-gpt-basdat \
    -V "Ubuntu 22.04 autoinstall" \
    -o ubuntu-22.04-frankeninstaller.iso \
    server-iso-extracted/



#vboxmanage storageattach autoinstall-test --storagectl IDE --port 0 --device 0 --type dvddrive --medium ubuntu-22.04-frankeninstaller.iso
    

