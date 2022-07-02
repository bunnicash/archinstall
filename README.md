# archinstall
Automated Arch Linux Installation <br>

<p>
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

### Using archinstall
- Traditionally, git is used for the setup:
```
pacman -Sy git --noconfirm
git clone https://github.com/bunnicash/archinstall
cd archinstall && chmod +x * && ./archinstall.sh
```

- Alternatively, you can use wget: 
```
wget https://github.com/bunnicash/archinstall/releases/download/latest/archinstall.tar.gz
tar -xvf archinstall.tar.gz
cd archinstall && chmod +x * && ./archinstall.sh
```
<br>

### Useful Information
- Use an EFI system, enable EFI mode when using VM's
- For the partitioning process, have a disk with at least 25GB, ideally 100GB
- Using WiFi, set it up using iwctl/iw: [Arch Wiki](https://wiki.archlinux.org/title/Network_configuration)
- Nvidia users are encouraged to edit the pre-made X11 config `/etc/X11/xorg.conf` e.g for custom DPI scaling!
- Be faster: When typing things into the terminal, press tab to auto-complete 
- Check out important archinstall news here: [NEWS.md](NEWS.md) <br><br>

### Features
- [x] Unattended installation mode with custom/imported configurations
- [x] Keymap setup, automated disk formatting/partitioning, bootloader setup (systemd-boot/grub)
- [x] Initial mirrorlist ranking, automated base package installation (pacstrap)
- [x] Multiple kernels available: linux, linux-lts, linux-zen, linux-hardened
- [x] Locale setup, automatically enable multilib, configuations for sudoers, hosts, limits
- [x] Main user and root account creation including their passwords
- [x] CPU microcode (ucode) detection and installation (intel/amd + bootloader config changes)
- [x] GPU detection and driver installation (+ hooks, mkinitcpio, bootloader, xorg-configs): nvidia, intel, amd, vm-qxl, vm-vmware
- [x] Automated installation of Display Servers, Display/Login Managers and Desktop Environments or Window Managers (+ services)
- [x] PulseAudio installation as well as a large selection of DE/WM-specific and mainsteam/standard apps
- [x] Memlock unlocks for emulation, Virtual Machine setup (virt-manager/libvirt/qemu/kvm and virtualbox)
- [x] Package group management, installation of user-specified packages <br><br>

### Testing / Contributing:
- Is there an unstable branch for testing? Yes, you can use the testing branch: `git clone -b testing https://github.com/bunnicash/archinstall`.
- This is also the key branch for most of the archinstall development, as changes are first introduced here and merged to main once deemed functional/stable. <br><br>

### Configurations:
- Archinstall uses the `config.archinstall` file that users may customize - this makes heavily automated deployments, e.g to virtual environments quick and easy
- To understand how the configuration file works and what you can do with it, here's the list of options you can change:<br>
<pre><b>Settings</b>
• drive: the target drive to install on, see "lsblk, blkid, hdparm" for more
• machineused: set to "hw" for real hardware, "vm" for virtual environments - determines formatting/discarding process
• defaultkeys: the keyboard layout used, see "localectl list-keymaps" for more

• part_swap: swap partition size for the linux installation, size x in GB = xG
• part_root: root partition size for the linux installation, size x in GB = xG

• bootloader: use systemd-boot (systemd) or GRUB (grub)

• kernelver: select one of 4 available kernels:
    - linux
    - linux-zen
    - linux-lts
    - linux-hardened

• defaultlocale: the main locale used for "locale-gen", see "cat /etc/locale.gen | grep (...)" for more
• defaultlocale2: this is a locale attachment required for "locale-gen", e.g if defaultlocale is "en_US.UTF-8", this will be "UTF-8"
• zone: the timezone used by the system, keep in mind many DE's need a separate GUI set-up for this too

• hostname: the system hostname, name of the machine 
• rootpass: password for the root account, superuser
• useracc: name for the user account 
• userpass: password for the user account 

• nvidia_module: nvidia now offers open source kernel modules - use: 
    - "nvidia-open" for open source kernel modules
    - "nvidia" for proprietary kernel modules
    - Note: There's no "open" modules for "nvidia-lts"

• guipreset: add a complete preset featuring DS, DM, DE/WM - use:
    - 0 for "Arch Server"
    - 1 for "Gnome Wayland"
    - 2 for "KDE Development Platform"
    - 3 for "Deepin Desktop"
    - 4 for "Cinnamon Development Platform"
    - 5 for "Cinnamon"
    - 6 for "XFCE"
    - 7 for "Gnome X11"
    - 8 for "XMonad"
    - 9 for "KDE"
    - Note: Development Platforms feature development-specific packages

• use_emu: install and modify a suite of emulators and their dependencies - use 1 to install, 0 to skip 
• use_vm: installs virtual machine managers/modules - use 1 for "all", 2 for "virt-manager", 3 for "virtualbox", 0 to skip
• use_wine: install wine and its utils/libs, useful for windows programs, games, proton - use 1 to install, 0 to skip

• packages_ext: add as many additional packages to be installed as you wish or 0 for none
</pre>
<br>
