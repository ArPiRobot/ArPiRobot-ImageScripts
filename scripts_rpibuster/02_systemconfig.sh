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
# script:      02_systemconfig.sh
# description: OS / system configuration for the image
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
    
    echo "Allowing passwordless sudo for user..."
    username=$(read_username)
    print_if_fail
    echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_arpirobot-nopasswd
    print_status

    echo "Changing hostname..."
    oldhost=$(hostname)
    print_if_fail
    echo "ArPiRobot-Robot" | tee /etc/hostname
    print_if_fail
    sed -i "s/${oldhost}/ArPiRobot-Robot/g" /etc/hosts
    print_status

    echo "Setting locale..."
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    print_if_fail
    locale-gen
    print_if_fail
    update-locale LANG=en_US.UTF-8
    print_status

    echo "Setting keyboard layout..."
    echo "# KEYBOARD CONFIGURATION FILE\n\n# Consult the keyboard(5) manual page.\n\nXKBMODEL=\"pc105\"\nXKBLAYOUT=\"us\"\nXKBVARIANT=\"\"\nXKBOPTIONS=\"\"\n\nBACKSPACE=\"guess\"" > /etc/default/keyboard
    print_if_fail
    systemctl restart keyboard-setup.service
    print_status

    # Enable SSH
    echo "Enabling ssh server..."
    systemctl enable ssh
    print_status

    # Enable hardware interfaces (SPI, I2C, UART, camera, etc)
    echo "Enabling hardware interfaces..."
    raspi-config nonint do_spi 0
    print_if_fail
    raspi-config nonint do_i2c 0
    print_if_fail
    raspi-config nonint do_ssh 0
    print_if_fail
    raspi-config nonint do_camera 0
    print_status

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file
