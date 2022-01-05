#!/bin/bash
#####################################################################################
#
# Copyright 2020 Marcus Behel
# 
# This file is part of ArPiRobot-ImageScripts.
# 
# ArPiRobot-ImageScripts is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ArPiRobot-ImageScripts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with ArPiRobot-ImageScripts.  If not, see <https://www.gnu.org/licenses/>.
#####################################################################################
# script:      final_stages.sh
# description: Does some cleanup and sets image up to exapand fs on next reboot.
# author:      Marcus Behel
# date:        6-21-2020
# version:     v1.0.0
#####################################################################################

# Note: Run as root

if ! [ $(id -u) = 0 ]; then
   echo "Run this script as root!"
   exit 1
fi


# Make read / write
mount -o rw,remount /
mount -o rw,remount /boot


# Delete ssh host keys (don't want these in the image. they need to be regenerated on each device)
rm -f /etc/ssh/ssh_host_*

# Patch the regenerate service to work with readonly filesystem
sed -i 's/Type=oneshot/&\nExecStartPre=\/bin\/mount -o rw,remount \//' /lib/systemd/system/regenerate_ssh_host_keys.service
sed -i 's/\[Install\]/ExecStartPost=\/bin\/mount -o ro,remount \/\n&/' /lib/systemd/system/regenerate_ssh_host_keys.service

# Enable the service
systemctl enable regenerate_ssh_host_keys



# Append quiet init=/usr/lib/raspi-config/init_resize.sh to the end of the first line in the file
sed -i '1 s/$/ quiet init=\/usr\/lib\/raspi-config\/init_resize.sh/' /boot/cmdline.txt 

# Modify raspbian's script to handle readonly file system
sed -i 's/mount \/boot/&\nmount -o rw,remount \/boot/' /usr/lib/raspi-config/init_resize.sh

# Write script
printf "#!/bin/sh\n### BEGIN INIT INFO\n# Provides:          resize2fs_once\n# Required-Start:\n# Required-Stop:\n# Default-Start: 3\n# Default-Stop:\n# Short-Description: Resize the root filesystem to fill partition\n# Description:\n### END INIT INFO\n. /lib/lsb/init-functions\ncase \"\$1\" in\n  start)\n    log_daemon_msg \"Starting resize2fs_once\"\n    mount -o rw,remount / &&\n    ROOT_DEV=\$(findmnt / -o source -n) &&\n    resize2fs \$ROOT_DEV &&\n    update-rc.d resize2fs_once remove &&\n    bash -c \"sleep 5;mount -o ro,remount /\" &\n    rm /etc/init.d/resize2fs_once &&\n    log_end_msg $?\n    ;;\n  *)\n    echo \"Usage: $0 start\" >&2\n    exit 3\n    ;;\nesac\n" > /etc/init.d/resize2fs_once

# Enable service next boot (it will delete itself after running once)
chmod +x /etc/init.d/resize2fs_once
update-rc.d resize2fs_once defaults


# Cleanup from image creation process
rm -rf /home/pi/ArPiRobot-ImageScripts
rm -rf /home/pi/ArPiRobot-RaspbianTools
rm -rf /home/pi/ArPiRobot-Tools
rm -rf /home/pi/ArPiRobot-CameraStreaming
rm -rf /home/pi/rpi-readonly

# Clear all bash history
rm /root/.bash_history
history -c
rm /home/pi/.bash_history


printf "The system will expand the root partition and filesystem on next boot. \nPress enter to power off..."
read n

poweroff
