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
# script:      stage2.sh
# description: Makes the Pi readonly
# author:      Marcus Behel
# date:        6-21-2020
# version:     v1.0.0
#####################################################################################

function print_status(){
    if [ $? -eq 0 ]
    then
	printf "Done.\n"
    else
	printf "Failed.\n"
	exit 1
    fi
}

function print_if_fail(){
    if [ $? -ne 0 ]
    then
	printf "Failed.\n"
    fi
}

LOGFILE=/root/setup_log.txt

################################################################################
# Prechecks (running as root and has intenet access)
################################################################################

if ! [ $(id -u) = 0 ]; then
   echo "Run this script as root!"
   exit 1
fi

if ping -q -c 1 -W 1 google.com >/dev/null; then
    true
else
    echo "Connect to the internet before running this script!"
    exit 1
fi

last=$(cat /root/last_setup_stage.txt)
if [ "$last" != "stage1" ]
then
    printf "Run stage 1 first.\n"
    exit 1
fi

################################################################################
# Stage operations
################################################################################

printf "Making sure dpkg configure finished after upgrade..."
dpkg --configure -a >> $LOGFILE 2>&1
print_status

printf "Installing git..."
apt-get -y install git >> $LOGFILE 2>&1
print_status

printf "Cloning rpi-readonly..."
cd /home/pi/ >> $LOGFILE 2>&1
print_if_fail
git clone https://gitlab.com/larsfp/rpi-readonly.git >> $LOGFILE 2>&1
print_status

printf "Running rpi-readonly script..."
cd /home/pi/rpi-readonly/
print_if_fail
echo "N" | ./setup.sh  >> $LOGFILE 2>&1
print_status




################################################################################
# Restart
################################################################################

printf "\n\n-------------------------\nEND OF STAGE 2\n-------------------------\n\n" >> $LOGFILE 2>&1

printf "The system will now reboot. Once rebooted run stage3.sh as root.\nPress enter to reboot now..."
read n

echo "stage2" > /root/last_setup_stage.txt

reboot
