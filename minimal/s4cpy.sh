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

#last=$(cat /root/last_setup_stage.txt)
#if [ "$last" != "stage3" ]
#then
#    printf "Run stage 3 first.\n"
#    exit 1
#fi

################################################################################
# Stage operations
################################################################################

printf "Remounting RW..."
mount -o rw,remount / >> /dev/null 2>&1
print_if_fail
mount -o rw,remount /boot >> /dev/null 2>&1
print_status

#printf "Doing one-time fix for keymap set..."
# This has to be done once while writable
#systemctl restart console-setup
#print_status

#printf "Installing python3 for ArPiRobot code..."
#apt-get -y install python3 python3-pip python3-setuptools python3-wheel >> $LOGFILE 2>&1
#print_status

#printf "Installing gstreamer for camera streaming..."
#apt-get -y install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-pulseaudio >> $LOGFILE 2>&1
#print_status

#printf "Installing required python3 libraries..."
#python3 -m pip install --upgrade pip >> $LOGFILE 2>&1
#print_if_fail
#pip3 install apscheduler ansicolors pyserial adafruit-circuitpython-motorkit >> $LOGFILE 2>&1
#print_status

#printf "Cloning ArPiRobot PythonLib..."
#git clone git@github.com:MB3hel/ArPiRobot-PythonLib.git /home/pi/ArPiRobot-PythonLib >> $LOGFILE 2>&1
#print_status

#printf "Installing ArPiRobot PythonLib..."
#cd /home/pi/ArPiRobot-PythonLib/ >> $LOGFILE 2>&1
#print_if_fail
#python3 setup.py install >> $LOGFILE 2>&1
#print_status

#printf "Making ArPiRobot directory..."
#su - pi -c "mkdir -p /home/pi/arpirobot/"  >> $LOGFILE 2>&1
#print_status

#printf "Setting up test program..."
#cp /home/pi/ArPiRobot-PythonLib/samples/test.py /home/pi/arpirobot/ >> $LOGFILE 2>&1
#print_if_fail
#su - pi -c 'echo "test.py" | tee /home/pi/arpirobot/main.txt' >> $LOGFILE 2>&1
#print_status

#printf "Clearing WiFi network settings..."
#printf 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\ncountry=US\n\nnetwork={\n        ssid="DUMMY_NETWORK"\n        psk="DUMMY_PASSWORD"\n}' | tee /etc/wpa_supplicant/wpa_supplicant.conf >> $LOGFILE 2>&1
#print_status

#printf "Clearing bash history..."
#history -c >> $LOGFILE 2>&1
#print_if_fail
#su - pi -c "history -c" >> $LOGFILE 2>&1
#print_status

#printf "Removing ssh keys..."
#rm -rf /home/pi/.ssh/* >> $LOGFILE 2>&1
#print_if_fail
#rm -rf /root/.ssh/*  >> $LOGFILE 2>&1
#print_status

#printf "Clearing ssh host keys..."
#rm -f /etc/ssh/ssh_host_* >> $LOGFILE 2>&1
#print_status

printf "Setting up to expand root fs at next boot..."
echo "init=/usr/lib/raspi-config/init_resize.sh" | tee -a /boot/config.txt
print_if_fail
printf "#!/bin/sh\n### BEGIN INIT INFO\n# Provides:          resize2fs_once\n# Required-Start:\n# Required-Stop:\n# Default-Start: 3\n# Default-Stop:\n# Short-Description: Resize the root filesystem to fill partition\n# Description:\n### END INIT INFO\n. /lib/lsb/init-functions\ncase \"\$1\" in\n  start)\n    log_daemon_msg \"Starting resize2fs_once\" &&\n    resize2fs /dev/$ROOT_PART &&\n    update-rc.d resize2fs_once remove &&\n    rm /etc/init.d/resize2fs_once &&\n    log_end_msg \$?\n    ;;\n  *)\n    echo \"Usage: \$0 start\" >&2\n    exit 3\n    ;;\nesac\n" | tee /etc/init.d/resize2fs_once
print_if_fail
chmod +x /etc/init.d/resize2fs_once >> $LOGFILE 2>&1
print_if_fail
systemctl enable resize2fs_once
print_status

################################################################################
# Restart
################################################################################

printf "\n\n-------------------------\nEND OF STAGE 4\n-------------------------\n\n" >> $LOGFILE 2>&1

printf "The minimal image configuration is now setup on this Pi. The system will now reboot.\nMake sure to test the image and make sure all sensitive information has been removed.\nPress enter to reboot now..."
read n

echo "stage4" > /root/last_setup_stage.txt

reboot