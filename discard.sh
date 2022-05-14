#!/bin/bash
## GPL-2.0 - @bunnicash, 2022

##Wiping: Securely erase target
lsblk && echo " "
read -r -p "[ARCHINSTALL] ==> Select the target drive: " targetd
echo " "
read -p "[ARCHINSTALL] ==> Are you installing this on a VM [y/n]? " machineused
echo " "
echo "Wiping target drive entirely!"
if [ $machineused == "y" ] || [ $machineused == "Y" ]; then
    blkdiscard -z -f /dev/$targetd ; sync
    echo "blkdiscard: done!"
elif [ $machineused == "n" ] || [ $machineused == "N" ]; then
    blkdiscard -v -f /dev/$targetd ; sync
    echo "blkdiscard: done!"
fi
echo " "
partprobe /dev/$targetd
echo $targetd > /root/archinstall/drive.txt
echo " "
