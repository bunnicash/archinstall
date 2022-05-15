#!/bin/bash
## GPL-2.0 - @bunnicash, 2022

##Keymap(1)
defaultkeys="de-latin1"
loadkeys $defaultkeys
read -p "==> Is this keyboard layout (keymap) correct: '$defaultkeys' [y/n]? " keyconfirm
echo " "
if [ $keyconfirm == "n" ] || [ $keyconfirm == "N" ]; then
    read -p "==> Select your desired keymap [de, es, fr, it, us, uk, il]: " layout
    localectl list-keymaps | grep $layout
    echo " "
    read -p "==> Enter specific keyboard layout from the search results [e.g: de-latin1, uk, il-heb]: " layout2
    loadkeys $layout2
    echo $layout2 > /root/archinstall/layout.txt
elif [ $keyconfirm == "y" ] || [ $keyconfirm == "Y" ]; then
    echo $defaultkeys > /root/archinstall/layout.txt
fi
echo " "

##WiFi
read -p "==> Set up an additional WiFi connection [y/n]? " wifi
if [ $wifi == "y" ] || [ $wifi == "Y" ]; then
    echo " " && ip -c a && echo " "
    read -p "==> Enter the WiFi device [e.g: wlan0] and the SSID (WiFi Network) separated with a space: " wdev ssid
    echo " " && echo "==> Connecting, please enter your WiFi password:"
    iw dev $wdev connect $ssid
    echo " " && echo "Attempting sync..."
    pacman -Sy
elif [ $wifi == "n" ] || [ $wifi == "N" ]; then
    echo "Skipping additional WiFi setup..."
fi
echo " "

##Partitioning
drive=$(cat /root/archinstall/drive.txt)
read -r -p "==> Enter a SWAP [e.g: 8G, 16G] and a ROOT partition size [e.g: 50G, 100G], separated by a space: " part_swap part_root && echo " "
echo "Starting the partitioning process on $drive"
umount -A --recursive /mnt
echo " "
partprobe /dev/$drive
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

##Bootloader(1), Kernel, Basic packages, Fstab
echo -ne "
==> Select the bootloader [systemd, grub] and
    the kernel [linux, linux-lts, linux-zen, linux-hardened], separated by a space"
read -r -p ": " bootloader kernelver && echo " "
if [ $bootloader == "systemd" ]; then
    use_bootloader=""
elif [ $bootloader == "grub" ]; then
    use_bootloader="grub efibootmgr os-prober"
fi
if [ $kernelver == "linux" ]; then
    use_kernelver="linux linux-docs linux-headers"
elif [ $kernelver == "linux-zen" ]; then
    use_kernelver="linux-zen linux-zen-docs linux-zen-headers"
elif [ $kernelver == "linux-lts" ]; then
    use_kernelver="linux-lts linux-lts-docs linux-lts-headers"
elif [ $kernelver == "linux-hardened" ]; then
    use_kernelver="linux-hardened linux-hardened-docs linux-hardened-headers"
fi
echo -e "Selected bootloader: $bootloader, selected kernel: $kernelver\n"
pacstrap -i /mnt $use_bootloader base base-devel $use_kernelver linux-firmware --noconfirm
echo $bootloader > /root/archinstall/bootloader.txt
echo $kernelver > /root/archinstall/kernelver.txt
genfstab -U -p /mnt >> /mnt/etc/fstab
echo " "
