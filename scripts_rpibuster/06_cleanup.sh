#!/usr/bin/env bash
#####################################################################################
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
# along with ArPiRobot-ImageScripts.  If not, see <https://www.gnu.org/licenses/>.
#####################################################################################
# script:      06_cleanup.sh
# description: Cleanup from image creation
# author:      Marcus Behel
#####################################################################################

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

    echo "Making system read / write..."
    mount -o rw,remount /
    print_if_fail
    mount -o rw,remount /boot
    print_status

    echo "Configuring to regenerate ssh host keys on next boot"
    rm -f /etc/ssh/ssh_host_*
    print_if_fail
    sed -i 's/Type=oneshot/&\nExecStartPre=\/bin\/mount -o rw,remount \//' /lib/systemd/system/regenerate_ssh_host_keys.service
    print_if_fail
    sed -i 's/\[Install\]/ExecStartPost=\/bin\/mount -o ro,remount \/\n&/' /lib/systemd/system/regenerate_ssh_host_keys.service
    print_if_fail
    systemctl enable regenerate_ssh_host_keys
    print_status

    echo "Removing clones repos..."
    username=$(read_username)
    print_if_fail
    rm -rf /home/${username}/ArPiRobot-ImageScripts
    print_if_fail
    rm -rf /home/${username}/ArPiRobot-Tools
    print_if_fail
    rm -rf /home/${username}/ArPiRobot-CameraStreaming
    print_status

    echo "Clearing WiFi network settings..."
    printf 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\ncountry=US\n\nnetwork={\n        ssid="DUMMY_NETWORK"\n        psk="DUMMY_PASSWORD"\n}' | tee /etc/wpa_supplicant/wpa_supplicant.conf
    print_status

    echo "Removing ssh keys..."
    rm -rf /home/${username}/.ssh/*
    print_if_fail
    rm -rf /root/.ssh/*
    print_status

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file
