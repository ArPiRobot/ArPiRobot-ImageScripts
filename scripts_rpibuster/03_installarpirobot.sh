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
# script:      03_installarpirobot.sh
# description: Install arpirobot specific software
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
    username=$(read_username)

    
    echo "Cloning ArPiRobot Camera Streaming repo"
    cd "/home/$username"
    print_if_fail
    git clone https://github.com/ArPiRobot/ArPiRobot-CameraStreaming.git
    print_if_fail
    chown -R ${username}:${username} ArPiRobot-CameraStreaming
    print_status


    echo "Installing camstream..."
    cd ArPiRobot-CameraStreaming
    print_if_fail
    chmod +x ./install.sh
    print_if_fail
    ./install.sh "${username}"
    print_if_fail

    arch=$(binarch $(which python3))
    if [ "$arch" = "ARM" ]; then
        chmod +x ./install_rtsp_server_armv6.sh
        print_if_fail
        ./install_rtsp_server_armv6.sh "${username}"
        print_if_fail
    elif [ "$arch" = "AArch64" ]; then
        chmod +x ./install_rtsp_server_aarch64.sh
        print_if_fail
        ./install_rtsp_server_aarch64.sh "${username}"
        print_if_fail
    else
        echo "Unknown architecture. Cannot run robot program!"
        false
        print_if_fail
    fi

    sed -i 's/libcamera/raspicam/g' /home/${username}/camstream/default.txt
    print_status

    echo "Cloning ArPiRobot tools repo..."
    cd "/home/$username"
    print_if_fail
    git clone https://github.com/ArPiRobot/ArPiRobot-Tools.git
    print_status

    echo "Installing tools..."
    cd ArPiRobot-Tools
    print_if_fail
    chmod +x ./install.sh
    print_if_fail
    ./install.sh "${username}"
    print_status

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file
