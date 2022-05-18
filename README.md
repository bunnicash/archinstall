# archinstall
Automated Arch Linux Installation <br>

<p>
</a>
    <a href="https://github.com/bunnicash/archinstall">
        <img src="https://img.shields.io/github/stars/bunnicash/archinstall?style=flat-square">
    </a>
    <a href="https://github.com/bunnicash/archinstall/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/bunnicash/archinstall?style=flat-square">
    </a>
    <a href="https://github.com/bunnicash/archinstall/issues">
        <img src="https://img.shields.io/github/issues/bunnicash/archinstall?style=flat-square">
    </a>
    <a href="https://github.com/bunnicash/archinstall">
        <img src="https://img.shields.io/tokei/lines/github/bunnicash/archinstall?style=flat-square">
    </a>
    <a href="https://github.com/bunnicash/archinstall">
        <img src="https://img.shields.io/github/last-commit/bunnicash/archinstall?style=flat-square">
    </a>
</p>
<br>

## Using archinstall
```
pacman -Sy git --noconfirm
git clone https://github.com/bunnicash/archinstall
cd archinstall && chmod +x * && ./archinstall.sh
```
<br>

## Useful Information
- Use an EFI system, enable EFI mode when using VM's
- For the partitioning wizard, have a disk with >=100GB
- Using WiFi, set it up using iwctl/iw (SSID with spaces: "SSIDpart1 part2"): [Arch Wiki: Network Config](https://wiki.archlinux.org/title/Network_configuration)
- Nvidia users are encouraged to edit the pre-made X11 config at /etx/X11/xorg.conf e.g for custom DPI scaling!
- Be faster: When typing things into the terminal, press tab to auto-complete <br><br>

## Features
- [x] Unattended installation mode with custom-made/imported configurations
- [x] Keymap setup, automated disk formatting/partitioning, bootloader setup (systemd-boot/grub)
- [x] Initial mirrorlist ranking, automated base package installation (pacstrap)
- [x] Multiple kernels available: linux, linux-lts, linux-zen, linux-hardened
- [x] Locale setup, automatically enable multilib, config mods such as sudoers, hosts, limits
- [x] User and root account creation including their passwords
- [x] Automated microcode (ucode) installation (intel/amd) as well as bootloader config changes
- [x] Driver detection and installation including hooks, mkinitcpio, bootloader, xorg configs for: nvidia, intel, amd, vm-qxl, vm-vmware
- [x] Automated XORG/Wayland, DM and DE/WM installation, as well as enabling required services
- [x] PulseAudio installation as well as a large selection of DE/WM-specific and mainsteam-standard apps
- [x] Memlock management for emulation, installation of both virt-manager (kvm/qemu/libvirt) and virtualbox
- [x] Program group management, ability to have additional programs installed from user input
- [x] And more... <br><br>

## Testing / Contributing:
- Is there an unstable branch for testing? Yes, you can use the testing branch: `git clone -b testing https://github.com/bunnicash/archinstall`.
- This is also the key branch for most of the archinstall development, as changes are first introduced here and merged to main once deemed functional/stable. <br><br>

## Configurations:
- Archinstall uses the `config.archinstall` file that users may edit/import - this makes heavily automated deployments, e.g to virtual environments quick and easy
- To understand how the configuration file works and what you can do with it, here's the list of options you can change:<br>
<pre><b>Settings</b>
• drive: the target drive to install on, see "lsblk" and "blkid" for more
• machineused: set to "hw" for real hardware, "vm" for virtual environments - determines formatting/discarding process
• defaultkeys: the keyboard layout used, see "localectl list-keymaps" for more

• part_swap: swap partition size for the linux installation, size x in GB = xG
• part_root: root partition size for the linux installation, size x in GB = xG

• bootloader: use systemd-boot (systemd) or GRUB (grub)
• kernelver: select one of 4 kernels (linux, linux-zen, linux-lts, linux-hardened)

• defaultlocale: the main locale used for "locale-gen", see "cat /etc/locale.gen | grep (...)" for more
• defaultlocale2: this is a locale attachment required for "locale-gen", e.g if defaultlocale is "en_US.UTF-8", this will be "UTF-8"
• zone: the timezone used by the system, keep in mind many DE's need a separate GUI set-up for this too

• hostname: the system hostname, name of the machine 
• rootpass: password for the root account, superuser (su)
• useracc: name for the user account 
• userpass: password for the user account 

• displayman: setup for the display server (XORG/X11) and the display manager - use A for "SDDM", B for "LightDM", C for "GDM" and 0 for none 
• de_wm: add the preferred desktop environment or window manager - use D for "KDE", E for "Cinnamon", F for "XFCE", G for "Gnome", H for "XMonad", I for "i3wm" and 0 for none

• guipreset: add a complete preset featuring DS, DM, DE/WM - use 1 for "Gnome Wayland", 2 for "KDE Development Platform", 3 for "Deepin Desktop", 4 for "Cinnamon Development Platform" and 0 for none (use either displayman + de_wm OR the guipreset)

• packages_ext: add as many additional packages to be installed as you wish or 0 for none
</pre>
<br>
