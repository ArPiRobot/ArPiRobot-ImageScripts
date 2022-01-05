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
# script:      stage3.sh
# description: Installs and configures required software for ArPiRobot robots
#              This is the last stage where internet access is required as the AP
#              is setup at the end of this stage.
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

function print_status_allow_fail(){
    if [ $? -eq 0 ]
    then
	printf "Done.\n"
    else
	printf "Failed.\n"
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
    exit 1
fi

################################################################################
# Stage operations
################################################################################

printf "Remounting RW..."
mount -o rw,remount /  >> /dev/null 2>&1
print_if_fail
mount -o rw,remount /boot >> /dev/null 2>&1
print_status

printf "Changing user pi password..."
printf "arpirobot\narpirobot" | passwd pi  >> $LOGFILE 2>&1
print_status

printf "Changing hostname..."
echo "ArPiRobot-Robot" | tee /etc/hostname  >> $LOGFILE 2>&1
print_if_fail
sed -i 's/raspberrypi/ArPiRobot-Robot/g' /etc/hosts  >> $LOGFILE 2>&1
print_status

printf "Changing locale..."
sed -i 's/en_GB.UTF-8 UTF-8/# en_GB.UTF-8 UTF-8/g' /etc/locale.gen  >> $LOGFILE 2>&1
print_if_fail

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen  >> $LOGFILE 2>&1
print_if_fail

locale-gen en_US.UTF-8 >> $LOGFILE 2>&1
print_if_fail

localectl set-locale LANG=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_CTYPE=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_NUMERIC=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_TIME=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_COLLATE=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_MONETARY=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_MESSAGES=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_PAPER=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_NAME=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_ADDRESS=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_TELEPHONE=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_MEASUREMENT=en_US.UTF-8  >> $LOGFILE 2>&1
print_if_fail
localectl set-locale LC_IDENTIFICATION=en_US.UTF-8  >> $LOGFILE 2>&1
print_status

printf "Changing keyboard layout..."
raspi-config nonint do_configure_keyboard us >> $LOGFILE 2>&1
print_status


printf "Enabling SSH, SPI, Camera, and I2C..."
raspi-config nonint do_spi 0  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_i2c 0  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_ssh 0  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_camera 0 >> $LOGFILE 2>&1
print_status

printf "Enabling console uart..."
printf "enable_uart=1\n" >> /boot/config.txt
print_status

printf "Disabling systemd-rfkill service as it does not work on readonly filesystem..."
systemctl disable systemd-rfkill.service >> $LOGFILE 2>&1
print_if_fail
systemctl mask systemd-rfkill.service >> $LOGFILE 2>&1
print_if_fail
systemctl disable systemd-rfkill.socket >> $LOGFILE 2>&1
print_if_fail
systemctl mask systemd-rfkill.socket >> $LOGFILE 2>&1
print_status

printf "Disabling dialy apt update and upgrade services..."
systemctl disable apt-daily.service >> $LOGFILE 2>&1
print_if_fail
systemctl disable apt-daily-upgrade.service >> $LOGFILE 2>&1
print_status

printf "Installing dos2unix..."
sudo apt install -y dos2unix >> $LOGFILE 2>&1
print_status

printf "Installing sysstat package for CPU usage monitoring..."
sudo apt install -y sysstat >> $LOGFILE 2>&1
print_status

printf "Installing python3 for ArPiRobot code..."
apt-get -y install python3 python3-pip python3-setuptools python3-setuptools-scm python3-wheel >> $LOGFILE 2>&1
print_status

# printf "Installing Java for ArPiRobot code..."
# Use JDK8 as it supports the Pi Zero
# apt-get -y install openjdk-8-jdk-headless >> $LOGFILE 2>&1
# print_status

printf "Installing required native libraries..."
apt-get -y install pigpio pigpiod pigpio-tools wiringpi libasound2-dev >> $LOGFILE 2>&1
print_status

printf "Installing iperf for network debugging..."
# This may not work on the Pi zero???
apt-get -y install iperf3 >> $LOGFILE 2>&1
print_status

printf "Installing gstreamer for camera streaming..."
apt-get -y install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-alsa gstreamer1.0-alsa gstreamer1.0-pulseaudio python3-gi python3-gst-1.0 gstreamer1.0-gl gstreamer1.0-omx-rpi-config gstreamer1.0-omx-rpi gstreamer1.0-omx >> $LOGFILE 2>&1
print_status

printf "Cloning ArPiRobot Camera Streaming repo"
git clone https://github.com/ArPiRobot/ArPiRobot-CameraStreaming.git /home/pi/ArPiRobot-CameraStreaming >> $LOGFILE 2>&1
chown -R pi:pi /home/pi/ArPiRobot-CameraStreaming
print_status

printf "Installing camstream..."
cd /home/pi/ArPiRobot-CameraStreaming >>$LOGFILE 2>&1
print_if_fail
chmod +x ./install.sh >> $LOGFILE 2>&1
print_if_fail
./install.sh >> $LOGFILE 2>&1
print_if_fail
chmod +x ./install_rtsp_server.sh >> $LOGFILE 2>&1
print_if_fail
./install_rtsp_server.sh  >> $LOGFILE 2>&1
print_if_fail
sed -i 's/libcamera/raspicam/g' /home/pi/camstream/default.txt
print_status

printf "Cloning ArPiRobot tools repo..."
git clone https://github.com/ArPiRobot/ArPiRobot-Tools.git /home/pi/ArPiRobot-Tools >> $LOGFILE 2>&1
print_status

printf "Installing tools..."
cd /home/pi/ArPiRobot-Tools>> $LOGFILE 2>&1
print_if_fail
chmod +x ./install.sh>> $LOGFILE 2>&1
print_if_fail
./install.sh >> $LOGFILE 2>&1
print_status

printf "Installing required software for network configuration..."
apt-get -y install hostapd dnsmasq >> $LOGFILE 2>&1
print_status

printf "Configuring hostapd to start on boot..."
systemctl unmask hostapd >> $LOGFILE 2>&1
print_if_fail
systemctl enable hostapd >> $LOGFILE 2>&1
print_status

printf "Unblocking WiFi..."
sudo rfkill unblock wlan >> $LOGFILE 2>&1
print_status_allow_fail

printf "Writing dnsmasq config file..."
printf "interface=wlan0\ndhcp-range=192.168.10.2,192.168.10.20,255.255.255.0,24h\ndomain=local\naddress=/ArPiRobot-Robot.local/192.168.10.1" | tee /etc/dnsmasq.conf >> $LOGFILE 2>&1
print_status

printf "Writing hostapd config file..."
printf "country_code=US\nieee80211d=1\ninterface=wlan0\nssid=ArPiRobot-RobotAP\nhw_mode=g\nchannel=6\nmacaddr_acl=0\nauth_algs=1\nignore_broadcast_ssid=0\nwpa=2\nwpa_passphrase=arpirobot123\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP\nwmm_enabled=1\n" | tee /etc/hostapd/hostapd.conf  >> $LOGFILE 2>&1
print_if_fail
printf 'DAEMON_CONF="/etc/hostapd/hostapd.conf"\n' | tee -a /etc/default/hostapd >> $LOGFILE 2>&1
print_status

printf "Fixing dnsmasq on readonly filesystem..."
echo "tmpfs /var/lib/misc tmpfs nosuid,nodev 0 0" | tee -a /etc/fstab >> $LOGFILE 2>&1
print_status

printf "Configuring dhcpcd..."
printf "interface wlan0\n    static ip_address=192.168.10.1/24\n    nohook wpa_supplicant" | tee -a /etc/dhcpcd.conf >> $LOGFILE 2>&1
print_status


################################################################################
# Restart
################################################################################

printf "\n\n-------------------------\nEND OF STAGE 3\n-------------------------\n\n" >> $LOGFILE 2>&1

printf "The system will now reboot. Once rebooted run stage4.sh as root.\nPress enter to reboot now..."
read n

echo "stage3" > /root/last_setup_stage.txt

reboot
