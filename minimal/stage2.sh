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
if [ "$last" != "stage1" ]
then
    printf "Run stage 1 first.\n"
fi

################################################################################
# Stage operations
################################################################################

printf "Installing git..."
apt-get -y install git >> $LOGFILE 2>&1
print_status

printf "Cloning rpi-readonly..."
cd /home/pi/ >> $LOGFILE 2>&1
print_if_fail
git clone https://gitlab.com/larsfp/rpi-readonly.git >> $LOGFILE 2>&1
print_status

printf "Running rpi-readonly script..."
echo "N" | ./setup.sh  >> $LOGFILE 2>&1
print_status()




################################################################################
# Restart
################################################################################

printf "The system will now reboot. Once rebooted run stage3.sh as root.\nPress enter to reboot now..."
read n

echo "stage2" > /root/last_setup_stage.txt

reboot
