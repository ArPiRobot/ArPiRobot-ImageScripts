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
# script:      99_functions.sh
# description: Helper functions used by other scripts
# author:      Marcus Behel
#####################################################################################

export AIS_LOGFILE=/root/arpirobot_image_scripts.log

# Print status of last command and exit on failure
function print_status(){
    if [ $? -eq 0 ]; then
	    printf "Done.\n"
    else
        printf "Failed.\n"
        exit 2
    fi
}

# Print if last command failed and exit 
function print_status_noexit(){
    if [ $? -eq 0 ]; then
	    printf "Done.\n"
    else
        printf "Failed.\n"
    fi
}

# Make sure the script is running as root. Exit if it is not
function check_root(){
    if ! [ $(id -u) = 0 ]; then
        echo "Run this script as root!"
        exit 1
    fi
}
