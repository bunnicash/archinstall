#!/bin/bash
## GPL-2.0 - @bunnicash, 2022

##Colors
c-cy () {
    echo -ne "\e[94m" # Cyan
}
c-df () {
    echo -ne "\e[39m" # Default
}

##Keymap(1)
defaultkeys="de-latin1"
loadkeys $defaultkeys
read -p "[ARCHINSTALL] ==> Is this keyboard layout (keymap) correct: '$defaultkeys' [y/n]? " keyconfirm
echo " "
if [ $keyconfirm == "n" ] || [ $keyconfirm == "N" ]; then
    read -p "[ARCHINSTALL] ==> Select your desired keymap [de, es, fr, it, us, uk, il]: " layout
    localectl list-keymaps | grep $layout
    echo " "
    read -p "[ARCHINSTALL] ==> Enter specific keyboard layout from the search results [e.g: de-latin1, uk, il-heb]: " layout2
    loadkeys $layout2
    echo $layout2 > /root/archinstall/layout.txt
elif [ $keyconfirm == "y" ] || [ $keyconfirm == "Y" ]; then
    echo $defaultkeys > /root/archinstall/layout.txt
fi
echo " "

##WiFi
read -p "[ARCHINSTALL] ==> Set up an additional WiFi connection [y/n]? " wifi
if [ $wifi == "y" ] || [ $wifi == "Y" ]; then
    echo " " && ip -c a && echo " "
    read -p "[ARCHINSTALL] ==> Enter the WiFi device [e.g: wlan0] and the SSID (WiFi Network) separated with a space: " wdev ssid
    echo " " && echo "[ARCHINSTALL] ==> Connecting, please enter your WiFi password:"
    iw dev $wdev connect $ssid
    echo " " && echo "Attempting sync..."
    pacman -Sy
elif [ $wifi == "n" ] || [ $wifi == "N" ]; then
    echo "Skipping additional WiFi setup..."
fi
echo " "

##Partitioning
drive=$(cat /root/archinstall/drive.txt)
echo -ne "[ARCHINSTALL] ==> Choose the SWAP partition      [e.g: 4G, 8G, 16G]
    and the ROOT partition size                  [e.g: 35G, 50G, 100G]
    All in one line, each separated with a space"
read -r -p ": " part_swap part_root && echo " "
echo -ne "Starting the partitioning process on $drive" && echo " "
umount -A --recursive /mnt
echo " "
partprobe /dev/$drive
# echo $drive > /root/archinstall/drive.txt
sgdisk -Z /dev/$drive
echo " "
sgdisk -a 2048 -o /dev/$drive
echo " "
sgdisk --new 1::+512M --typecode 1:EF00 --change-name 1:"boot" /dev/$drive
sgdisk --new 2::+$part_swap --typecode 2:8200 --change-name 2:"swap" /dev/$drive
sgdisk --new 3::+$part_root --typecode 3:8300 --change-name 3:"root" /dev/$drive
sgdisk --new 4::0 --typecode 4:8300 --change-name 4:"home" /dev/$drive
echo " "
partprobe /dev/$drive
mkfs.fat -F32 /dev/${drive}1
mkswap /dev/${drive}2
swapon /dev/${drive}2
mkfs.ext4 /dev/${drive}3
mkfs.ext4 /dev/${drive}4
mount /dev/${drive}3 /mnt && mkdir /mnt/boot && mkdir /mnt/home
mount /dev/${drive}1 /mnt/boot
mount /dev/${drive}4 /mnt/home
echo " " && lsblk && sleep 2 && echo " "

##Mirrors, Keyring, Pacman
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy archlinux-keyring pacman-contrib --noconfirm
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
echo " "

##Bootloader(1), Basic packages, Fstab
read -p "[ARCHINSTALL] ==> Select the bootloader [systemd, grub]: " bootloader
if [ $bootloader == "systemd" ]; then
    echo "Preparing bootloader: systemd-boot..."
    pacstrap -i /mnt base base-devel linux linux-firmware linux-headers --noconfirm
elif [ $bootloader == "grub" ]; then
    echo "Preparing bootloader: grub"
    pacstrap -i /mnt grub efibootmgr os-prober base base-devel linux linux-firmware linux-headers --noconfirm
fi
echo $bootloader > /root/archinstall/bootloader.txt
genfstab -U -p /mnt >> /mnt/etc/fstab
echo " "
