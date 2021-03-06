#!/bin/bash
## Copyright (C) 2022 bunnicash "@bunnicash" and licensed under GPL-2.0
source /root/archinstall/config.archinstall 

## Locale
echo "$defaultlocale $defaultlocale2" >> /etc/locale.gen
locale-gen
echo "LANG=$defaultlocale" > /etc/locale.conf
export LANG=$defaultlocale
echo " "

## Keymap(2)
echo "KEYMAP=$defaultkeys" >> /etc/vconsole.conf

## Timezone
ln -sf /usr/share/zoneinfo/$zone > /etc/localtime
hwclock --systohc
timedatectl set-ntp true

## Pacman Tweaks (arch-chroot /mnt/root)
cp /etc/pacman.conf /etc/pacman.backup
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
echo -ne "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf
pacman -Sy
echo " "

## Accounts
echo "$hostname" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname" >> /etc/hosts
# Root Account
(echo $rootpass; echo $rootpass) | passwd
echo " "
# User Account
useradd -m -g users -G wheel,storage,power -s /bin/bash $useracc
(echo $userpass; echo $userpass) | passwd $useracc
echo -ne "
%wheel ALL=(ALL) ALL
Defaults rootpw
" >> /etc/sudoers
echo " "

## Bootloader(2)
if [ $bootloader == "systemd" ]; then  # https://wiki.archlinux.org/title/systemd-boot 
    bootctl install
elif [ $bootloader == "grub" ]; then  # https://wiki.archlinux.org/title/GRUB#Installation (--removable)
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi
echo " "

## Services
init_enable () {
    for service in $services; do
        systemctl enable $service
    done
    echo -e "Enabled $services \n"
}

pacman -S dhcpcd networkmanager --noconfirm --needed
services="dhcpcd.service NetworkManager.service fstrim.timer"
init_enable

## CPU Microcode (ucode)
config_ucode () {
    pacman -S $set_ucode --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo -ne "title Arch Linux
linux /vmlinuz-$kernelver
initrd /$set_ucode.img
initrd /initramfs-$kernelver.img
" > /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
}

proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then  # CPU: Intel
    set_ucode="intel-ucode"
    config_ucode
elif grep -E "AuthenticAMD" <<< ${proc_type}; then  # CPU: AMD
    set_ucode="amd-ucode"
    config_ucode
fi

## GPU Drivers (discrete, virtual, integrated)
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then  # GPU: NVIDIA (https://archlinux.org/packages/)
    if [ $kernelver == "linux-lts" ]; then  # nvidia-lts
        nvidia_package="nvidia-lts"
    elif [ $kernelver == "linux" ]; then  # nvidia, nvidia-open
        nvidia_package="$nvidia_module"
    else nvidia_package="$nvidia_module-dkms"  # nvidia-dkms, nvidia-open-dkms
    fi

    pacman -S mesa lib32-mesa $nvidia_package nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia libglvnd lib32-libglvnd nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw nvidia-drm.modeset=1" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi

    # Change mkinitcpio.conf:
    cp /etc/mkinitcpio.conf /etc/mkinitcpio.backup
    sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

    # Create Nvidia Pacman Hook ("nvidia" "nvidia.hook" both work):
    mkdir /etc/pacman.d/hooks
    echo -ne "[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=$nvidia_package

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
" > /etc/pacman.d/hooks/nvidia

    # Create X11 config:
    nvidia-xconfig
    cp /etc/X11/xorg.conf /etc/X11/xorg.backup
    echo -ne "
Section \"OutputClass\"
    Identifier \"nvidia dpi settings\"
    MatchDriver \"nvidia-drm\"
    Option \"UseEdidDpi\" \"False\"
    Option \"DPI\" \"96 x 96\"
EndSection
" >> /etc/X11/xorg.conf
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then  # GPU: AMD / Radeon
    pacman -S mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
elif grep -E "Intel Corporation UHD" <<< ${gpu_type} || grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then  # GPU: Intel (Not recommended: "xf86-video-intel")
    pacman -S mesa lib32-mesa libva-intel-driver libvdpau-va-gl vulkan-intel lib32-vulkan-intel libva-utils vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
elif grep -E "VMware SVGA II Adapter" <<< ${gpu_type}; then  # GPU: VMware / VirtualBox
    pacman -S mesa lib32-mesa xf86-video-vmware vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
elif grep -E "Red Hat, Inc. QXL paravirtual graphic card" <<< ${gpu_type}; then  # GPU: KVM, VirtManager
    pacman -S mesa lib32-mesa xf86-video-qxl vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
fi
echo " "

## Presets: Fully Preconfigured User Environments
get_xorg () {
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
}

if [ $guipreset == "0" ]; then  # Arch Server
    echo "Arch Linux Server selected, skipping graphical environments and standard app suite!"
    exit 0
elif [ $guipreset == "1" ]; then  # Gnome Wayland ("echo $XDG_SESSION_TYPE" = "wayland")
    pacman -S gdm gnome --noconfirm
    pacman -S gnome-bluetooth bluez bluez-tools file-roller gnome-terminal nautilus eog evince gnome-calculator gnome-calendar gnome-color-manager gnome-tweaks gnome-power-manager gnome-system-monitor gnome-control-center gnome-screenshot ntfs-3g exfatprogs cups ufw gufw colord system-config-printer --noconfirm --needed
    services="gdm.service bluetooth.service ufw.service cups.service"
    init_enable
elif [ $guipreset == "2" ]; then  # KDE Development Platform
    get_xorg
    pacman -S sddm --noconfirm
    pacman -S plasma okular kate breeze kuickshow ksystemlog bluez bluez-tools firewalld ntfs-3g exfatprogs spectacle konsole partitionmanager dolphin ark unrar p7zip colord-kde kcalc network-manager-applet system-config-printer cups --noconfirm
    pacman -R discover --noconfirm
    pacman -S git github-cli clang gcc-fortran lua nodejs typescript tk python-numpy r php nasm cmake vulkan-devel faudio gnome-keyring meson edk2-ovmf --noconfirm
    services="sddm.service bluetooth.service firewalld.service cups.service"
    init_enable
elif [ $guipreset == "3" ]; then  # Deepin Desktop Environment (DDE)
    get_xorg
    pacman -S lightdm --noconfirm
    pacman -S deepin deepin-extra deepin-kwin bluez bluez-tools ntfs-3g exfatprogs ufw gufw cups --noconfirm
    services="lightdm.service bluetooth.service ufw.service cups.service"
    init_enable
    echo "greeter-session=lightdm-deepin-greeter" >> /etc/lightdm/lightdm.conf
elif [ $guipreset == "4" ]; then  # Cinnamon Development Platform
    get_xorg
    pacman -S gdm --noconfirm
    pacman -S cinnamon ttf-dejavu nemo-terminal nemo-fileroller system-config-printer xreader eog eog-plugins blueberry bluez bluez-tools cups gnome-terminal firewalld gnome-disk-utility gparted exfatprogs ntfs-3g colord colord-gtk --noconfirm
    pacman -S git github-cli clang gcc-fortran lua nodejs typescript tk python-numpy r php nasm cmake vulkan-devel unrar p7zip faudio gnome-screenshot copyq breeze kate gnome-keyring gnome-calculator meson edk2-ovmf --noconfirm
    services="gdm.service bluetooth.service firewalld.service cups.service"
    init_enable
elif [ $guipreset == "5" ]; then  # Cinnamon Standard
    get_xorg
    pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings lightdm-slick-greeter --noconfirm
    pacman -S cinnamon ttf-dejavu nemo-fileroller system-config-printer gnome-keyring gnome-calculator xreader xed eog eog-plugins blueberry bluez bluez-tools cups gnome-terminal ufw gufw gnome-disk-utility gparted exfatprogs ntfs-3g colord --noconfirm
    services="lightdm.service bluetooth.service ufw.service cups.service"
    init_enable
    echo "greeter-session=lightdm-slick-greeter" >> /etc/lightdm/lightdm.conf
elif [ $guipreset == "6" ]; then  # XFCE Standard
    get_xorg
    pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm
    pacman -S xfce4 xfce4-goodies gnome-disk-utility xfce4-settings thunar-archive-plugin colord colord-gtk galculator file-roller thunar-media-tags-plugin gvfs bluez bluez-tools firewalld ntfs-3g exfatprogs network-manager-applet system-config-printer cups xfce-terminal xfce-screenshooter --noconfirm
    services="lightdm.service bluetooth.service firewalld.service cups.service"
    init_enable
elif [ $guipreset == "7" ]; then  # Gnome Standard (X11)
    get_xorg
    pacman -S gdm gnome --noconfirm
    pacman -S gnome-bluetooth bluez bluez-tools file-roller gnome-terminal nautilus eog evince gnome-calculator gnome-calendar gnome-color-manager gnome-tweaks gnome-power-manager gnome-system-monitor gnome-control-center gnome-screenshot ntfs-3g exfatprogs cups ufw gufw colord system-config-printer --noconfirm --needed
    services="gdm.service bluetooth.service ufw.service cups.service"
    init_enable
elif [ $guipreset == "8" ]; then  # Xmonad (/etc/sddm.conf)
    get_xorg
    pacman -S sddm xmonad xmonad-contrib dmenu xmobar xterm --noconfirm
    services="sddm.service"
    init_enable
    echo "To get started with xmonad, see: https://xmonad.org/documentation.html" && sleep 4
elif [ $guipreset == "9" ]; then  # KDE Standard
    get_xorg
    pacman -S sddm plasma okular kate breeze kuickshow ksystemlog bluez bluez-tools firewalld ntfs-3g exfatprogs spectacle konsole partitionmanager dolphin ark unrar p7zip colord-kde kcalc network-manager-applet system-config-printer cups --noconfirm
    pacman -R discover --noconfirm
    services="sddm.service bluetooth.service firewalld.service cups.service"
    init_enable
fi
echo " "

## ALSA-Pulse
pacman -S pulseaudio pulseaudio-alsa alsa-plugins libpulse lib32-libpulse lib32-alsa-plugins pavucontrol --noconfirm --needed

## Standard Applications
pacman -S nano bash-completion fuse2 fuse3 wget unzip lm_sensors ffmpeg obs-studio mpv celluloid thunderbird firefox discord gimp papirus-icon-theme neofetch arch-wiki-docs htop bashtop --noconfirm --needed
pacman -S libreoffice-still ttf-caladea ttf-carlito ttf-dejavu ttf-liberation ttf-linux-libertine-g noto-fonts noto-fonts-cjk noto-fonts-emoji --noconfirm --needed

## Groups (Substitute User: Quickly add users to groups)
su_group () {
    su $useracc --command="exit"
}

## Emulation, Memlock
if [ $use_emu == "1" ]; then
    pacman -S ppsspp desmume realtime-privileges --noconfirm --needed
    echo " "
    echo -ne "
*      soft      memlock      unlimited
*      hard      memlock      unlimited
" >> /etc/security/limits.conf
    su_group
    usermod -a -G realtime $useracc
fi 

## Virtual Machines
get_virtmanager () {
    pacman -S dnsmasq qemu-full libvirt virt-manager --noconfirm
    yes | pacman -S ebtables
    systemctl enable libvirtd.service
    su_group
    usermod -a -G libvirt $useracc
}

get_virtualbox () {
    pacman -S virtualbox-host-dkms virtualbox virtualbox-guest-iso --noconfirm
    su_group
    usermod -a -G vboxusers $useracc
}

if [ $use_vm == "1" ]; then
    get_virtmanager
    get_virtualbox
elif [ $use_vm == "2" ]; then
    get_virtmanager
elif [ $use_vm == "3" ]; then
    get_virtualbox
fi 
echo " "

## Gaming 
if [ $use_wine == "1" ]; then
    pacman -S wine wine-gecko wine-mono vkd3d lib32-vkd3d winetricks --noconfirm
    echo -e "Installed WINE\n"
fi

## Additional Packages
if [ ${#packages_ext} -ge 2 ]; then
    pacman -S $packages_ext --noconfirm
    echo -e "Installed $packages_ext\n"
fi
