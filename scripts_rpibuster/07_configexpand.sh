#!/usr/bin/env bash
################################################################################
#
# Copyright 2022 Marcus Behel
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
# along with ArPiRobot-ImageScripts. If not, see <https://www.gnu.org/licenses/>
################################################################################
# script:      07_configexpand.sh
# description: Configure filesystem to expand on next boot
# author:      Marcus Behel
################################################################################

# Initialization
DIR=$(realpath $(dirname "$0"))         # get directory of this script
ORIG_CWD=$(pwd)                         # store original working directory
cd "$DIR"                               # cd to script directory
source "$DIR/../99_functions.sh"        # source helper functions file
check_root                              # ensure running as root

# Body of the script
{
    script=$(basename "$0")
    lastscript=$(read_last_stage)
    echo "Running \"${script}\":"
    echo "Last run script: \"${lastscript}\"."
    echo "--------------------------------------------------------------------------------"

    # Code goes here
    # Configure system to expand root filesystem on next boot
    # NOTE: RasPiOS has a specific way this is done (and is replicated here)
    #       For general systems though, a service to run growpart and resize2fs should work

    fs_mode=$(mount | sed -n -e 's/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p')
    if [ "$fs_mode" = "ro" ]; then
        echo "Making system read / write..."
        mount -o rw,remount /
        print_if_fail
        mount -o rw,remount /boot
        print_status
    fi

    echo "Configuring to grow partition on next boot"
    # Append quiet init=/usr/lib/raspi-config/init_resize.sh to the end of the first line in the file
    sed -i '1 s/$/ quiet init=\/usr\/lib\/raspi-config\/init_resize.sh/' /boot/cmdline.txt 
    print_if_fail

    # Modify raspbian's script to handle readonly file system
    sed -i 's/mount \/boot/&\nmount -o rw,remount \/boot/' /usr/lib/raspi-config/init_resize.sh
    print_if_fail

    # Write script
    printf "#!/bin/sh\n### BEGIN INIT INFO\n# Provides:          resize2fs_once\n# Required-Start:\n# Required-Stop:\n# Default-Start: 3\n# Default-Stop:\n# Short-Description: Resize the root filesystem to fill partition\n# Description:\n### END INIT INFO\n. /lib/lsb/init-functions\ncase \"\$1\" in\n  start)\n    log_daemon_msg \"Starting resize2fs_once\"\n    mount -o rw,remount / &&\n    ROOT_DEV=\$(findmnt / -o source -n) &&\n    resize2fs \$ROOT_DEV &&\n    update-rc.d resize2fs_once remove &&\n    rm /etc/init.d/resize2fs_once &&\n    log_end_msg $?\n    ;;\n  *)\n    echo \"Usage: $0 start\" >&2\n    exit 3\n    ;;\nesac\n" > /etc/init.d/resize2fs_once
    print_if_fail

    # Enable service next boot (it will delete itself after running once)
    chmod +x /etc/init.d/resize2fs_once
    print_if_fail
    update-rc.d resize2fs_once defaults
    print_status

    # Clear history again
    echo "Clearing bash history again..."
    rm -f /root/.bash_history
    print_if_fail
    history -c
    print_if_fail
    rm -f /home/pi/.bash_history
    print_status

    echo "Delete the ImageScripts directory, remove logs, and poweroff."

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file

