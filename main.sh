#!/bin/bash
## GPL-2.0 - @bunnicash, 2022

##Locale
defaultlocale="en_US.UTF-8"
defaultlocale2="UTF-8"
read -p "==> Is this locale correct: '$defaultlocale $defaultlocale2' [y/n]? " localeconfirm
echo " "
if [ $localeconfirm == "n" ] || [ $localeconfirm == "N" ]; then
    read -p "==> Starting locale setup, enter [fr, es, de, en, US, GB, AU] to find: " nation
    cat /etc/locale.gen | grep $nation
    echo " "
    read -r -p "==> Enter your locale as listed [e.g: en_US.UTF-8 UTF-8, en_IL UTF-8]: " locale locale2
    echo "$locale $locale2" >> /etc/locale.gen
    locale-gen
    echo "LANG=$locale" > /etc/locale.conf
    export LANG=$locale
elif [ $localeconfirm == "y" ] || [ $localeconfirm == "Y" ]; then
    echo "$defaultlocale $defaultlocale2" >> /etc/locale.gen
    locale-gen
    echo "LANG=$defaultlocale" > /etc/locale.conf
    export LANG=$defaultlocale
fi
echo " "

##Keymap(2)
layout2=$(cat /root/archinstall/layout.txt)
echo "KEYMAP=$layout2" >> /etc/vconsole.conf

##Timezone
ls /usr/share/zoneinfo && echo " "
read -p "==> Enter your timezone [e.g: Europe/Berlin, America/New_York, Asia/Tokyo]: " zone
ln -sf /usr/share/zoneinfo/$zone > /etc/localtime
echo " "
hwclock --systohc
timedatectl set-ntp true

##Multilib, Pacman, Trim
systemctl enable fstrim.timer
cp /etc/pacman.conf /etc/pacman.backup
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
echo -ne "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf
pacman -Sy nano bash-completion --noconfirm
echo " "

##Accounts
read -p "==> Enter your desired system hostname: " hostname
echo "$hostname" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname" >> /etc/hosts
echo " "
# Root Account
echo "==> Set a password for the root account:" && passwd
echo " "
# User Account
read -p "==> Create a user account by entering a user name in lowercase: " useracc
useradd -m -g users -G wheel,storage,power -s /bin/bash $useracc
echo "==> Set a password for the user account:" && passwd $useracc
echo -ne "
%wheel ALL=(ALL) ALL
Defaults rootpw
" >> /etc/sudoers
echo " "

##Efivarfs, Bootloader(2)
bootloader=$(cat /root/archinstall/bootloader.txt)
if [ $bootloader == "systemd" ]; then
    bootctl install
    # https://wiki.archlinux.org/title/systemd-boot 
elif [ $bootloader == "grub" ]; then
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    # https://wiki.archlinux.org/title/GRUB#Installation ( --removable )
fi
echo " "
pacman -S dhcpcd networkmanager -noconfirm --needed
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
echo " "

##Drivers
# Import: drive = targetd in discard.sh  |  kernelver = kernelver in startup.sh
drive=$(cat /root/archinstall/drive.txt)
kernelver=$(cat /root/archinstall/kernelver.txt)
if [ $kernelver == "linux-lts" ]; then
    nvidia_package="nvidia-lts"
else nvidia_package="nvidia-dkms"
fi
# GET-CPU: Intel / AMD
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Intel microcode: Installing and generating bootloader default.conf"
    pacman -Sy --noconfirm intel-ucode
    if [ $bootloader == "systemd" ]; then
        echo -ne "title Arch Linux
linux /vmlinuz-$kernelver
initrd /intel-ucode.img
initrd /initramfs-$kernelver.img
" > /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "AMD microcode: Installing and generating bootloader default.conf"
    pacman -Sy --noconfirm amd-ucode
    if [ $bootloader == "systemd" ]; then
        echo -ne "title Arch Linux
linux /vmlinuz-$kernelver
initrd /amd-ucode.img
initrd /initramfs-$kernelver.img
" > /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
fi
# GET-GPU: NVIDIA
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S mesa lib32-mesa $nvidia_package nvidia-utils opencl-nvidia lib32-opencl-nvidia libglvnd lib32-libglvnd lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    # Change bootloader default.conf, append:
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
    echo "Nvidia GPU: Done. Changed mkinitcpio.conf, bootloader-default.conf, xorg.conf and created pacman hook."
# GET-GPU: AMD / Radeon
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
    echo "AMD GPU: Done. No further config needed."
# GET-GPU: Intel (Packages "vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader" enough, DE-specific? Often not recommended: "xf86-video-intel")
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S mesa lib32-mesa libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
    echo "Intel GPU: Done. No further config needed."
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S mesa lib32-mesa libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
    echo "Intel GPU: Done. No further config needed."
# GET-GPU: VM's
elif grep -E "VMware SVGA II Adapter" <<< ${gpu_type}; then
    pacman -S mesa lib32-mesa xf86-video-vmware vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
    echo "VMware GPU: Done. No further config needed."
elif grep -E "Red Hat, Inc. QXL paravirtual graphic card" <<< ${gpu_type}; then
    pacman -S mesa lib32-mesa xf86-video-qxl vulkan-tools --noconfirm
    if [ $bootloader == "systemd" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/${drive}3) rw" >> /boot/loader/entries/default.conf
    elif [ $bootloader == "grub" ]; then
        echo "grub: skipping further bootloader config"
    fi
    echo "VM QXL GPU: Done. No further config needed."
fi
echo " "

##GUI Setup (DS + DM + DE/WM)
echo " " && echo -ne "Starting graphical user interface installation...


Using XORG/X11 as Display Server [DS]:

  Display Manager [DM]:    |    Desktop Environment [DE] / Window Manager [WM]:
  ( A )  SDDM              |    ( D )  KDE
  ( B )  LightDM           |    ( E )  Cinnamon
  ( C )  GDM               |    ( F )  XFCE
                           |    ( G )  Gnome
                           |    ( H )  XMonad
                           |    ( I )  i3


Custom configurations:

  ( 1 )  Wayland  [DS] with GDM     [DM] and Gnome    [DE]: Wayland-only
  ( 2 )  XORG/X11 [DS] with SDDM    [DM] and KDE      [DE]: Dev Platform
  ( 3 )  XORG/X11 [DS] with LightDM [DM] and DDE      [DE]: Deepin Desktop
  ( 4 )  XORG/X11 [DS] with GDM     [DM] and Cinnamon [DE]: Dev Platform

"
echo " " && echo -ne "
==> Select a display manager [A, B, C] and a desktop environment / window manager [D, E, F, G, H, I]
    separated by a space
    
    Alternatively, select a single custom configuration [1, 2, 3, 4]"
read -r -p ": " displayman de_wm && echo " "
if [ $displayman == "A" ]; then
    # DM - SDDM
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S sddm --noconfirm
    systemctl enable sddm.service
elif [ $displayman == "B" ]; then
    # DM - LightDM
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings lightdm-slick-greeter --noconfirm
    systemctl enable lightdm.service
    echo "greeter-session=lightdm-slick-greeter" >> /etc/lightdm/lightdm.conf
elif [ $displayman == "C" ]; then
    # DM - GDM
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S gdm --noconfirm
    systemctl enable gdm.service
elif [ $displayman == "1" ]; then
    # Custom - Gnome Wayland (Command "echo $XDG_SESSION_TYPE" shows "wayland" post-boot)
    pacman -S gdm --noconfirm
    systemctl enable gdm.service
    pacman -S gnome --noconfirm
    pacman -S gnome-bluetooth bluez bluez-tools file-roller gnome-terminal nautilus eog evince gnome-calculator gnome-calendar gnome-color-manager gnome-tweaks gnome-power-manager gnome-system-monitor gnome-control-center gnome-screenshot ntfs-3g exfatprogs cups ufw gufw colord system-config-printer --noconfirm
    systemctl enable bluetooth.service
    systemctl enable ufw.service
    systemctl enable cups.service
    de_wm="0"
elif [ $displayman == "2" ]; then
    # Custom - KDE development platform
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S sddm --noconfirm
    systemctl enable sddm.service
    pacman -S plasma okular kate breeze ksystemlog bluez bluez-tools firewalld ntfs-3g exfatprogs spectacle konsole dolphin ark unrar p7zip colord-kde kcalc network-manager-applet system-config-printer cups --noconfirm
    pacman -R discover --noconfirm
    pacman -S git tk r php cmake eog gnome-disk-utility vulkan-devel nano faudio gnome-keyring --noconfirm
    systemctl enable bluetooth.service
    systemctl enable firewalld.service
    systemctl enable cups.service
    de_wm="0"
elif [ $displayman == "3" ]; then
    # Custom - Deepin Desktop Environment (DDE)
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S deepin deepin-extra deepin-kwin lightdm bluez bluez-tools ntfs-3g exfatprogs ufw gufw cups --noconfirm
    systemctl enable lightdm.service
    echo "greeter-session=lightdm-deepin-greeter" >> /etc/lightdm/lightdm.conf
    systemctl enable bluetooth.service
    systemctl enable ufw.service
    systemctl enable cups.service
    de_wm="0"
elif [ $displayman == "4" ]; then
    # Custom - Cinnamon development platform
    pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xterm --noconfirm
    pacman -S gdm --noconfirm
    systemctl enable gdm.service
    pacman -S cinnamon ttf-dejavu nemo-terminal nemo-fileroller system-config-printer xreader eog eog-plugins blueberry bluez bluez-tools cups gnome-terminal firewalld gnome-disk-utility exfatprogs ntfs-3g colord colord-gtk --noconfirm
    pacman -S git tk r php cmake vulkan-devel nano unrar p7zip faudio gnome-screenshot copyq gedit gspell gnome-keyring gnome-calculator --noconfirm
    systemctl enable bluetooth.service
    systemctl enable firewalld.service
    systemctl enable cups.service
    de_wm="0"
fi
echo " "
if [ $de_wm == "D" ]; then
    # DE/WM - KDE
    pacman -S plasma okular kate breeze kuickshow ksystemlog bluez bluez-tools firewalld ntfs-3g exfatprogs spectacle konsole partitionmanager dolphin ark unrar p7zip colord-kde kcalc network-manager-applet system-config-printer cups --noconfirm
    pacman -R discover --noconfirm
    systemctl enable bluetooth.service
    systemctl enable firewalld.service
    systemctl enable cups.service
elif [ $de_wm == "E" ]; then
    # DE/WM - Cinnamon
    pacman -S cinnamon ttf-dejavu nemo-fileroller system-config-printer gnome-keyring gnome-calculator xreader xed eog eog-plugins blueberry bluez bluez-tools cups gnome-terminal ufw gufw gnome-disk-utility exfatprogs ntfs-3g colord --noconfirm
    systemctl enable bluetooth.service
    systemctl enable ufw.service
    systemctl enable cups.service
elif [ $de_wm == "F" ]; then
    # DE/WM - XFCE
    pacman -S xfce4 xfce4-goodies gnome-disk-utility xfce4-settings thunar-archive-plugin colord colord-gtk galculator file-roller thunar-media-tags-plugin gvfs bluez bluez-tools firewalld ntfs-3g exfatprogs network-manager-applet system-config-printer cups xfce-terminal xfce-screenshooter --noconfirm
    systemctl enable bluetooth.service
    systemctl enable firewalld.service
    systemctl enable cups.service
elif [ $de_wm == "G" ]; then
    # DE/WM - Gnome (X11)
    pacman -S gnome --noconfirm
    pacman -S gnome-bluetooth bluez bluez-tools file-roller gnome-terminal nautilus eog evince gnome-calculator gnome-calendar gnome-color-manager gnome-tweaks gnome-power-manager gnome-system-monitor gnome-control-center gnome-screenshot ntfs-3g exfatprogs cups ufw gufw colord system-config-printer --noconfirm
    systemctl enable bluetooth.service
    systemctl enable ufw.service
    systemctl enable cups.service
elif [ $de_wm == "H" ]; then
    # DE/WM - XMonad (https://wiki.archlinux.org/title/xmonad)
    pacman -S xmonad xmonad-contrib dmenu xmobar xterm --noconfirm
    echo -e "\nTo get started with xmonad, see: https://xmonad.org/documentation.html" && sleep 4 
elif [ $de_wm == "I" ]; then
    # DE/WM - i3 (https://wiki.archlinux.org/title/i3)
    pacman -S i3-wm i3lock i3status i3blocks dmenu konsole --noconfirm
    cp /etc/X11/xinit/xinitrc/ ~/.xinitrc
    echo -e "\nTo get started with i3wm, see: https://i3wm.org/docs/" && sleep 4
fi
echo " "

##ALSA-Pulse
pacman -S pulseaudio pulseaudio-alsa alsa-plugins libpulse lib32-libpulse lib32-alsa-plugins pavucontrol --noconfirm --needed

##Standard Applications
# Basic Programs
pacman -S lm_sensors mpv celluloid thunderbird firefox discord gimp papirus-icon-theme neofetch arch-wiki-docs htop bashtop --noconfirm --needed
# LibreOffice, Fonts
pacman -S libreoffice-still ttf-caladea ttf-carlito ttf-dejavu ttf-liberation ttf-linux-libertine-g noto-fonts noto-fonts-cjk noto-fonts-emoji --noconfirm --needed
# OBS
pacman -S ffmpeg obs-studio --noconfirm --needed
# Emus, Memlock   (group: realtime)
pacman -S ppsspp desmume realtime-privileges --noconfirm --needed
echo " "
echo -ne "
*      soft      memlock      unlimited
*      hard      memlock      unlimited
" >> /etc/security/limits.conf
# VMs(1)   (group: libvirt)
pacman -S dnsmasq qemu-full libvirt virt-manager --noconfirm
yes | pacman -S ebtables
systemctl enable libvirtd.service
echo " "
# VMs(2)   (group: vboxusers)
pacman -S virtualbox-host-dkms virtualbox virtualbox-guest-iso --noconfirm
echo " "
# AppImage Dependencies (https://github.com/AppImage/AppImageKit/wiki/FUSE, https://github.com/AppImage/AppImageKit/issues/1120)
pacman -S fuse fuse3 --noconfirm --needed
echo " "
# Custom packages
read -p "==> Enter any additional packages you want to install, or press enter for none: " packages_ext
if [ ${#packages_ext} -ge 2 ]; then
    pacman -S $packages_ext --noconfirm
fi
echo " "

##Groups
su $useracc --command="exit"
usermod -a -G realtime $useracc
usermod -a -G libvirt $useracc
usermod -a -G vboxusers $useracc
echo " "
