#!/bin/bash

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

printf "" | tee $LOGFILE > /dev/null 2>&1

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

################################################################################
# Stage operations
################################################################################

printf "Will now setup Raspbian Lite as minimal ArPiRobot image.\n"

printf "Setting lower resolution..."
sed -i 's/#hdmi_group=1/hdmi_group=1/g' /boot/config.txt
print_if_fail
sed -i 's/#hdmi_mode=1/hdmi_mode=4/g' /boot/config.txt
print_status


printf "Updating apt repos..."
apt-get -y update >> $LOGFILE 2>&1
print_status

printf "Upgrading packages..."
apt-get -y upgrade >> $LOGFILE 2>&1
print_status


################################################################################
# Restart
################################################################################

printf "\n\n-------------------------\nEND OF STAGE 1\n-------------------------\n\n" >> $LOGFILE 2>&1

printf "The system will now reboot. Once rebooted run stage2.sh as root.\nPress enter to reboot now..."
read n

echo "stage1" > /root/last_setup_stage.txt

reboot
