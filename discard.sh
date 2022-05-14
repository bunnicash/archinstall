#!/bin/bash
## GPL-2.0 - @bunnicash, 2022

##Wiping: Securely erase target
lsblk && echo " "
read -r -p "==> Enter the target drive and the machine type [vm/hw], separated by a space: " targetd machineused
echo -e "\nWiping target drive entirely!"
if [ $machineused == "vm" ] || [ $machineused == "VM" ]; then
    blkdiscard -z -f /dev/$targetd ; sync
elif [ $machineused == "hw" ] || [ $machineused == "HW" ]; then
    blkdiscard -v -f /dev/$targetd ; sync
fi
echo -e "blkdiscard: done!\n"
partprobe /dev/$targetd
echo $targetd > /root/archinstall/drive.txt
