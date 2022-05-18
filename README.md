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
- Using WiFi from the start, set it up using iwctl/iw (SSID with spaces: "SSIDpart1 part2"): [Arch Wiki: Network Config](https://wiki.archlinux.org/title/Network_configuration)
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

### FAQ:
- Is there an unstable branch for testing? Yes, you can use the testing branch: `git clone -b testing https://github.com/bunnicash/archinstall` <br><br>
