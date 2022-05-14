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

## Get started (main/testing branch)
```
pacman -Sy git --noconfirm
git clone https://github.com/bunnicash/archinstall
cd archinstall && chmod +x * && ./archinstall.sh
```
<br>

## Useful Information
- Use an EFI system, enable EFI mode when using VM's
- For the partitioning wizard, have a disk with >=100GB (Use sensible SWAP and ROOT partition sizes)
- Using WiFi, you'll have to set it up (iwctl/iw): *iw dev wlan0 connect SSID* (SSID with spaces, type: "SSIDpart1 part2")
- Nvidia users are encouraged to edit the pre-made X11 config at /etx/X11/xorg.conf e.g for custom DPI scaling
- When typing names, e.g for folders or programs in the terminal, press tab to autocomplete <br><br>

## Features
- [x] Keymap setup, automated disk formatting/partitioning, bootloader setup (systemd-boot/grub)
- [x] Initial mirrorlist ranking, automated base package installation (base, base-devel, linux...)
- [x] Locale setup, automatically enable multilib, config mods such as sudoers, hosts, limits
- [x] User and root account creation including their passwords
- [x] Automated microcode (ucode) installation (intel/amd) as well as bootloader config changes as well as
- [x] Driver detection and installation including hooks, mkinitcpio, bootloader, xorg configs for: nvidia, intel, amd, vm-qxl, vm-vmware
- [x] Automated XORG/Wayland, DM and DE/WM installation, as well as enabling required services
- [x] PulseAudio installation as well as a large selection of DE/WM-specific and mainsteam-standard apps
- [x] Memlock management for emulation, installation of both virt-manager (kvm/qemu/libvirt) and virtualbox
- [x] Program group management, ability to have additional programs installed from user input
- [x] Colorful and easy to understand input prompts
- [x] And more... <br><br>

### FAQ:
- Is there an unstable branch for testing? Yes, you can use the testing branch: `git clone -b testing https://github.com/bunnicash/archinstall` <br>
