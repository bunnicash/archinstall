#!/bin/bash
## GPL-2.0 - @bunnicash, 2022
version="v3.1"

##Colors
c-cy () {
    echo -ne "\e[94m" # Cyan
}
c-df () {
    echo -ne "\e[39m" # Default
}

##Archinstall
cd /root/archinstall
c-cy && echo -ne "

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
chmod +x *.sh
bash discard.sh
bash startup.sh
cd /root && mv archinstall /mnt/root
arch-chroot /mnt /root/archinstall/main.sh
echo " " && rm -rf /mnt/root/archinstall && umount -l /mnt
c-cy && echo -ne "

            -                |
           /#\               |
          /###\              |
         /#####\             |
        /#######\            |        The installation is complete, rebooting in 3 seconds...
       /##(   )##\           |
      /##/     \##\          |
     /#/         \#\         |
     '             '         |

" && c-df
sleep 3 && reboot now

