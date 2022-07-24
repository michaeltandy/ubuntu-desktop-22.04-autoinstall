
wget https://mirrors.vinters.com/ubuntu-releases/22.04/ubuntu-22.04-live-server-amd64.iso

# Create ISO distribution dirrectory:
mkdir -p iso/nocloud/

# Or extract ISO and fix permissions:
xorriso -osirrox on -indev "ubuntu-22.04-live-server-amd64.iso" -extract / iso && chmod -R +w iso

# Create empty meta-data file:
touch iso/nocloud/meta-data

# Copy user-data file:
cp user-data iso/nocloud/user-data

# Update boot flags with cloud-init autoinstall:
## Should look similar to this: initrd=/casper/initrd quiet autoinstall ds=nocloud;s=/cdrom/nocloud/ ---
sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
#sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg


# Disable mandatory md5 checksum on boot:
md5sum iso/.disk/info > iso/md5sum.txt
sed -i 's|iso/|./|g' iso/md5sum.txt

# (Optionally) Regenerate md5:
# The find will warn 'File system loop detected' and return non-zero exit status on the 'ubuntu' symlink to '.'
# To avoid that, temporarily move it out of the way
mv iso/ubuntu .
(cd iso; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} \; > ../md5sum.txt)
mv md5sum.txt iso/
mv ubuntu iso

# Create Install ISO from extracted dir (Ubuntu):
xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ubuntu-22.04-amd64-autoinstall.iso \
  -J -l -b boot/grub/i386-pc/eltorito.img -c boot.catalog -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e '-not-found-any-more-' -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
  iso/boot iso


Alternative:
sudo xorriso -as mkisofs -isohybrid-mbr isolinux/isohdpfx.bin \ 
-c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 \
-boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
-isohybrid-gpt-basdat -o ../custom-ubuntu.iso .



cp ubuntu-22.04-live-server-amd64.iso new.iso && \
    xorriso -boot_image any keep \
        -dev new.iso \
        -map iso/nocloud/meta-data /nocloud/meta-data \
        -map user-data /nocloud/user-data \
        -map iso/boot/grub/grub.cfg /boot/grub/grub.cfg \
        -map iso/md5sum.txt /md5sum.txt
        
        \
        -map desktop-pool /ubuntu-desktop/pool \
        -map desktop-dists /ubuntu-desktop/dists


cp ubuntu-22.04-live-server-amd64.iso guesswork.iso && \
    xorriso -boot_image any keep \
        -dev guesswork.iso \
        -map iso/nocloud/meta-data /nocloud/meta-data \
        -map user-data /nocloud/user-data \
        -map iso/boot/grub/grub.cfg /boot/grub/grub.cfg \
        -map iso/md5sum.txt /md5sum.txt \
        -map desktop-iso/casper/filesystem.manifest /casper/ubuntu-desktop.manifest \
        -map desktop-iso/casper/filesystem.size /casper/ubuntu-desktop.size \
        -map desktop-iso/casper/filesystem.squashfs /casper/ubuntu-desktop.squashfs \
        -map desktop-iso/casper/filesystem.squashfs.gpg /casper/ubuntu-desktop.squashfs.gpg \
        -map desktop-iso/casper/filesystem.squashfs.gpg /casper/ubuntu-desktop.squashfs.gpg \
        -map new-packages-installation/ new-packages-installation/ \
        -map install-sources.yaml /casper/install-sources.yaml \
        -map packages-to-purge.txt packages-to-purge.txt && \
    vboxmanage storageattach autoinstall-test --storagectl IDE --port 0 --device 0 --type dvddrive --medium guesswork.iso 
    
    
# Made shim-signed, efibootmgr etc become uninstallable because they're not in desktop-dists???

subiquity/TimeZone
/snap/subiquity/3359/usr/bin/subiquity-server
/snap/subiquity/3359/usr/bin/python3.8 -m subiquity.cmd.server

apt-get --print-uris --yes install ubuntu-desktop plymouth-theme-ubuntu-logo grub-gfxpayload-lists

--option=Dir::Etc::sourcelist=/tmp/tmpewm1smkf/sources.list', '--option=Dir::Etc::sourceparts=/tmp/tmpewm1smkf/sources.list.d'


late-commands are logged to /var/log/syslog 
