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
if [ "$last" != "stage2" ]
then
    printf "Run stage 2 first.\n"
fi

################################################################################
# Stage operations
################################################################################

printf "Remounting RW..."
mount -o rw,remount /  >> $LOGFILE 2>&1
print_if_fail
mount -o rw,remount /boot >> $LOGFILE 2>&1
print_status

printf "Changing user pi password..."
printf "arpirobot\narpirobot" | passwd pi  >> $LOGFILE 2>&1
print_status

printf "Changing hostname..."
echo "ArPiRobot-Robot" > /etc/hostname
print_if_fail
sed -i 's/raspberrypi/ArPiRobot-Robot/g' /etc/hosts
print_status

printf "Changing locale..."
sed -i 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen
print_if_fail

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
print_if_fail

locale-gen en_US.UTF-8
print_if_fail

localectl set-locale LANG=en_US.UTF-8
print_if_fail
localectl set-locale LC_CTYPE=en_US.UTF-8
print_if_fail
localectl set-locale LC_NUMERIC=en_US.UTF-8
print_if_fail
localectl set-locale LC_TIME=en_US.UTF-8
print_if_fail
localectl set-locale LC_COLLATE=en_US.UTF-8
print_if_fail
localectl set-locale LC_MONETARY=en_US.UTF-8
print_if_fail
localectl set-locale LC_MESSAGES=en_US.UTF-8
print_if_fail
localectl set-locale LC_PAPER=en_US.UTF-8
print_if_fail
localectl set-locale LC_NAME=en_US.UTF-8
print_if_fail
localectl set-locale LC_ADDRESS=en_US.UTF-8
print_if_fail
localectl set-locale LC_TELEPHONE=en_US.UTF-8
print_if_fail
localectl set-locale LC_MEASUREMENT=en_US.UTF-8
print_if_fail
localectl set-locale LC_IDENTIFICATION=en_US.UTF-8
print_status

printf "Changing keyboard layout..."
printf '# KEYBOARD CONFIGURATION FILE\n# Consult the keyboard(5) manual page.\nXKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\n\nBACKSPACE="guess"\n' | tee  /etc/default/keyboard
print_status


################################################################################
# Restart
################################################################################

printf "The system will now reboot. Once rebooted run stage4.sh as root.\nPress enter to reboot now..."
read n

echo "stage3" > /root/last_setup_stage.txt

reboot
