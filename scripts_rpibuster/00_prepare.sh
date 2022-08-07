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
# script:      00_prepare.sh
# description: Updates software and prepares the OS for image creation
# author:      Marcus Behel
#####################################################################################


# Initialization
DIR=$(realpath $(dirname "$0"))         # get directory of this script
ORIG_CWD=$(pwd)                         # store original working directory
cd "$DIR"                               # cd to script directory
source "$DIR/../99_functions.sh"        # source helper functions file
check_root                              # ensure running as root
check_internet                          # ensure internet connectivity
clear_files                             # clear old log and state files 

# Body of the script
{
    script=$(basename "$0")
    lastscript=$(read_last_stage)
    echo "Running \"${script}\":"
    echo "Last run script: \"${lastscript}\"."
    echo "--------------------------------------------------------------------------------"

    # Write image version name to a file (user enters name)
    printf "Version name for this image: "
    read image_ver
    printf "${image_ver}\n"
    echo "Writing image version file..."
    printf "$image_ver" > /usr/local/arpirobot-image-version.txt
    print_status

    # Setup username for the image
    echo "Adding arpirobot user..."
    adduser --disabled-password --gecos "" arpirobot
    print_if_fail
    printf "arpirobot\narpirobot" | passwd arpirobot
    print_if_fail
    for i in `grep -E "(:|,)pi(:,|$)" /etc/group|cut -f1 -d:` ; do
        addgroup mynewuser $i
        print_if_fail
    done
    write_username arpirobot
    print_status

    echo "Changing pi user password..."
    printf "notdefault\nnotdefault" | passwd pi
    print_status

    echo "Updating apt repos..."
    apt-get -y update
    print_status

    echo "Upgrading packages..."
    apt-get -y upgrade
    print_status

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file

