# Ubuntu 22.04 Desktop Autoinstall

This script makes an auto-installer for Ubuntu 22.04 Desktop.

This is very similar to [Molnár Péter's network-based autoinstall](https://www.molnar-peter.hu/en/ubuntu-jammy-netinstall-pxe.html) but (a) that needs a network connection, and (b) that installs the server version, then installs more packages to convert it into a desktop version - resulting in an install that's different to an install from the desktop ISO (e.g. network interfaces that aren't managed by NetworkManager)

I also drew inspiration from [covertsh's ubuntu autoinstall generator](https://github.com/covertsh/ubuntu-autoinstall-generator/blob/main/ubuntu-autoinstall-generator.sh) which is far higher effort than my script here!

## What it does

* We use the server install ISO (because that's capable of autoinstall with an encrypted hard drive) 
* But we extract the `squashfs` from the desktop ISO, because that's got the desktop packages in it.
* Then we convert from a 'full' desktop install to a 'minimal' desktop install, which basically means removing packages.
* For some reason this process doesn't put a working kernel on /boot, so we install one, along with anything else in `packages-to-install/`

You might have to tweak things if you want it to line up closely with what you'd get from installing with the Desktop ISO - I'm targeting business laptops, so I've only tested with EFI/secure boot.
