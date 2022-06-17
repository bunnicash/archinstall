#!/bin/bash
## Copyright (C) 2022 bunnicash "@bunnicash" and licensed under GPL-2.0
source /root/archinstall/config.archinstall 

## Keymap(1)
loadkeys $defaultkeys

## Partitioning
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

## Mirrors, Keyring, Pacman
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy archlinux-keyring pacman-contrib --noconfirm
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
echo " "

## Bootloader(1), Kernel, Basic packages, Fstab
if [ $bootloader == "systemd" ]; then
    use_bootloader="systemd"
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
pacstrap -i /mnt $use_bootloader base base-devel $use_kernelver linux-firmware --noconfirm
genfstab -U -p /mnt >> /mnt/etc/fstab
echo " "
