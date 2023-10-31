# Ubuntu 22.04 Desktop Autoinstall

# THIS MAKES AN ISO THAT WILL OVERWRITE THE DISK OF ANY COMPUTER THAT BOOTS IT WITHOUT ASKING FOR CONFIRMATION so don't boot it in any computer you don't want wiped.

This script makes an auto-installer for Ubuntu 22.04 Desktop.

This is very similar to [Molnár Péter's network-based autoinstall](https://www.molnar-peter.hu/en/ubuntu-jammy-netinstall-pxe.html) but (a) that needs a network connection, and (b) that installs the server version, then installs more packages to convert it into a desktop version - resulting in an install that's different to an install from the desktop ISO (e.g. network interfaces that aren't managed by NetworkManager)

I also drew inspiration from [covertsh's ubuntu autoinstall generator](https://github.com/covertsh/ubuntu-autoinstall-generator/blob/main/ubuntu-autoinstall-generator.sh) which is far higher effort than my script here!

## What it does

* We use the server install ISO (because that's capable of autoinstall with an encrypted hard drive) 
* But we extract the `squashfs` from the desktop ISO, because that's got the desktop packages in it.
* Then we convert from a 'full' desktop install to a 'minimal' desktop install, which basically means removing packages.

You might have to tweak things if you want it to line up closely with what you'd get from installing with the Desktop ISO - I'm targeting business laptops, so I've only tested with EFI/secure boot.

## Two ways to get packages into your custom install

I've experimented with two ways to customise the packages in the installation, while still allowing offline installation.

* If you want to generate your install ISO without being root, check out the `without-root-or-modifying-squashfs` branch. Instead of modifying the `squashfs` filesystem images, that branch creates an extra store of packages on the ISO and installs them at install-time.

* On the other hand, in this `main` branch we modify two `squashfs` filesystems, installing the packages once upfront. This makes for a faster install, but you have to run parts of the build process as root.

## Places to customise

* `desktop-squashfs-modifications.sh` for most modifications to the installed Ubuntu image.
* `user-data` for disk layout, disk encryption password, and miscellaneous commands run during install.
* `make-autoinstall-image.sh` scripts the actual creation of the ISO, copying files into the ISO etc.
* `attempt-wifi-connection.sh` for wifi during install (to allow the installation of updates)
* `setup-secureboot-mok.sh` fiddles around with secure boot, setting up a machine owner key

# Other useful info

* [curtin yaml examples](https://github.com/canonical/curtin/blob/master/examples/apt-source.yaml)
* [curtin documentation](https://curtin.readthedocs.io/en/latest/index.html)
* [autoinstall reference](https://ubuntu.com/server/docs/install/autoinstall-reference)
* [apt-get sources.list info](https://wiki.debian.org/SourcesList)
* [subiquity source code](https://github.com/canonical/subiquity/blob/324ff0bc8fa5a5f3c843f59dedba7f955050e9a6/subiquity/server/controllers/install.py#L326)
* [Ubuntu Live CD customization](https://help.ubuntu.com/community/LiveCDCustomization)
