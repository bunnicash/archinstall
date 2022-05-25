#!/bin/bash
## Copyright (C) 2022 bunnicash "@bunnicash" and licensed under GPL-2.0
version="v3.5"

##Colors
c-bl () {
    echo -ne "\e[94m" # Blue
}
c-df () {
    echo -ne "\e[39m" # Default
}

##Archinstall
cd /root/archinstall
chmod +x *.sh
c-bl && echo -ne "

            -                |
           /#\               |
          /###\              |
         /#####\             |
        /#######\            |        Welcome to archinstall $version!
       /##(   )##\           |
      /##/     \##\          |
     /#/         \#\         |
     '             '         |

" && c-df
# Configuration
read -p "Edit archinstall configuration [1], import a custom config [2] or use defaults [3]? " archconfig
if [ $archconfig == "1" ]; then
    nano /root/archinstall/config.archinstall
elif [ $archconfig == "2" ]; then
    read -p "Specify the absolute path to your config file [e.g /mnt/device/folder]: " importconfig
    cp -f $importconfig/config.archinstall /root/archinstall
elif [ $archconfig == "3" ]; then
    echo "Using default configuration..."
fi
# Modules
bash discard.sh
bash startup.sh
cd /root && mv archinstall /mnt/root
arch-chroot /mnt /root/archinstall/main.sh
echo " " && rm -rf /mnt/root/archinstall && umount -l /mnt
c-bl && echo -ne "

            -                |
           /#\               |
          /###\              |
         /#####\             |
        /#######\            |        The installation is complete, rebooting in 2 seconds...
       /##(   )##\           |
      /##/     \##\          |
     /#/         \#\         |
     '             '         |

" && c-df
sleep 2 && reboot now

