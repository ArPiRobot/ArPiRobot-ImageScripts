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
# script:      99_functions.sh
# description: Helper functions used by other scripts
# author:      Marcus Behel
################################################################################

export AIS_LOGFILE=/root/arpirobot_image.log
export AIS_STATEFILE=/root/arpirobot_image.state
export AIS_USERNAME=/usr/local/arpirobot-user.txt

# Print status of last command and exit on failure
function print_status(){
    if [ $? -eq 0 ]; then
	    printf "Done.\n"
    else
        printf "Failed.\n"
        exit 2
    fi
}

# Print and exit if a command failed
function print_if_fail(){
    if [ $? -ne 0 ]; then
	    printf "Failed.\n"
        exit 2
    fi
}

# Print status of last command
function print_status_noexit(){
    if [ $? -eq 0 ]; then
	    printf "Done.\n"
    else
        printf "Failed.\n"
        exit 2
    fi
}

# Print if a command failed
function print_if_fail_noexit(){
    if [ $? -ne 0 ]; then
	    printf "Failed.\n"
        exit 2
    fi
}

# Make sure the script is running as root. Exit if it is not
function check_root(){
    if ! [ $(id -u) = 0 ]; then
        echo "Run this script as root!"
        exit 1
    fi
}

function check_internet(){
    if ping -q -c 1 -W 1 google.com > /dev/null 2>&1; then
        true
    else
        echo "Connect to the internet before running this script!"
        exit 3
    fi
}

# Write the name of the file that last ran to the state file
function write_last_stage(){
    script=$(basename "$0")
    printf "$script" > "$AIS_STATEFILE"
}

# Read the name of the file that last ran from the state file
function read_last_stage(){
    script=$(cat "$AIS_STATEFILE" 2> /dev/null)
    printf "$script"
}

# Delete old log and state files
function clear_files(){
    rm "$AIS_LOGFILE" 2> /dev/null
    rm "$AIS_STATEFILE"  2> /dev/null
}

# Write username used on this image
function write_username(){
    printf "$1" > "$AIS_USERNAME"
}

# Read username used on this image
function read_username(){
    un=$(cat "$AIS_USERNAME" 2> /dev/null)
    printf "$un"
}

# Get architecture of an ELF binary
function binarch(){
    printf "$(readelf -h $1 | grep Machine: | sed -r 's/\s+Machine:\s+//g')"
}

function reboot_delayed(){
    nohup sh -c 'sleep 5 && reboot' > /dev/null 2>&1 &
}
