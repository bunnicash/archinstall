#!/bin/bash
## GPL-2.0 - @bunnicash, 2022
source /root/archinstall/config.archinstall 

##Wiping: Securely erase target
echo -e "\nWiping target drive entirely!"
if [ $machineused == "vm" ] || [ $machineused == "VM" ]; then
    blkdiscard -z -f /dev/$drive ; sync
elif [ $machineused == "hw" ] || [ $machineused == "HW" ]; then
    blkdiscard -v -f /dev/$drive ; sync
fi
echo -e "blkdiscard: done!\n"
partprobe /dev/$drive