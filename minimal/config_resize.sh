#!/bin/bash

# Note: Run as root

if ! [ $(id -u) = 0 ]; then
   echo "Run this script as root!"
   exit 1
fi

# Append quiet init=/usr/lib/raspi-config/init_resize.sh to the end of the first line in the file
sed -i '1 s/$/ quiet init=\/usr\/lib\/raspi-config\/init_resize.sh/' /boot/cmdline.txt 

# Modify raspbian's script to handle readonly file system
sed -i 's/mount \/boot/&\nmount -o rw,remount \/boot/' /usr/lib/raspi-config/init_resize.sh

# Write script
printf "#!/bin/sh\n### BEGIN INIT INFO\n# Provides:          resize2fs_once\n# Required-Start:\n# Required-Stop:\n# Default-Start: 3\n# Default-Stop:\n# Short-Description: Resize the root filesystem to fill partition\n# Description:\n### END INIT INFO\n. /lib/lsb/init-functions\ncase \"\$1\" in\n  start)\n    log_daemon_msg \"Starting resize2fs_once\"\n    mount -o rw,remount /\n    ROOT_DEV=\$(findmnt / -o source -n) &&\n    resize2fs \$ROOT_DEV &&\n    update-rc.d resize2fs_once remove &&\n    rm /etc/init.d/resize2fs_once &&\n    mount -o ro,remount /\n    log_end_msg $?\n    ;;\n  *)\n    echo \"Usage: $0 start\" >&2\n    exit 3\n    ;;\nesac\n" > /etc/init.d/resize2fs_once

# Enable service next boot (it will delete itself after running
chmod +x /etc/init.d/resize2fs_once
update-rc.d resize2fs_once defaults

printf "The system will expand the root partition and filesystem on next boot. \nPress enter to power off..."
read n

poweroff
