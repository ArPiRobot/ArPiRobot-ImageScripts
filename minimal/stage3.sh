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

locale-gen en_US.UTF-8  >> $LOGFILE 2>&1
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


printf "Enabling SSH, SPI, and I2C..."
raspi-config nonint do_spi 0  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_i2c 0  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_ssh 0  >> $LOGFILE 2>&1
print_status

printf "Cloning ArPiRobot Raspbian tools repo..."
git clone git@github.com:MB3hel/ArPiRobot-RaspbianTools.git /home/pi/ArPiRobot-RaspbianTools >> $LOGFILE 2>&1
print_status

printf "Installing raspbian tools..."
cd /home/pi/ArPiRobot-RaspbianTools>> $LOGFILE 2>&1
print_if_fail
chmod +x ./install.sh>> $LOGFILE 2>&1
print_if_fail
./install.sh >> $LOGFILE 2>&1
print_status

printf "Installing other required software for network configuration..."
apt-get -y install hostapd dnsmasq >> $LOGFILE 2>&1
print_status

printf "Writing dnsmasq config file..."
printf "interface=lo,ap0\nserver=8.8.8.8\ndomain-needed\nbogus-priv\ndhcp-range=192.168.10.2,192.168.10.10,255.255.255.0,24h" | tee /etc/dnsmasq.conf >> $LOGFILE 2>&1
print_status

printf "Writing hostapd config file..."
printf "channel=11\nssid=ArPiRobot-RobotAP\nwpa_passphrase=arpirobot123\ninterface=ap0\nhw_mode=g\nmacaddr_acl=0\nauth_algs=1\nwpa=2\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP\ndriver=nl80211" | tee /etc/hostapd/hostapd.conf  >> $LOGFILE 2>&1
print_if_fail
#sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="/etc/hostapd/hostapd.conf"/g' /etc/default/hostapd >> $LOGFILE 2>&1
printf 'DAEMON_CONF="/etc/hostapd/hostapd.conf"\n' | tee -a /etc/default/hostapd >> $LOGFILE 2>&1
print_status

printf "Fixing dnsmasq on readonly filesystem..."
echo "tmpfs /var/lib/misc tmpfs nosuid,nodev 0 0" | tee -a /etc/fstab >> $LOGFILE 2>&1
print_status

printf "Configuring dhcpcd..."
printf "interface ap0\nstatic ip_address=192.168.10.1\nnohook wpa_supplicant" | tee -a /etc/dhcpcd.conf >> $LOGFILE 2>&1
print_status


printf "Disabling networking services on startup (handled by custom service)..."
systemctl stop hostapd   >> $LOGFILE 2>&1
print_if_fail
systemctl stop dnsmasq  >> $LOGFILE 2>&1
print_if_fail
systemctl stop dhcpcd  >> $LOGFILE 2>&1
print_if_fail
systemctl disable hostapd  >> $LOGFILE 2>&1
print_if_fail
systemctl disable dnsmasq  >> $LOGFILE 2>&1
print_if_fail
systemctl disable dhcpcd  >> $LOGFILE 2>&1
print_if_fail
systemctl unmask hostapd >> $LOGFILE 2>&1
print_status

################################################################################
# Restart
################################################################################

printf "\n\n-------------------------\nEND OF STAGE 3\n-------------------------\n\n" >> $LOGFILE 2>&1

printf "The system will now reboot. Once rebooted run stage4.sh as root.\nPress enter to reboot now..."
read n

echo "stage3" > /root/last_setup_stage.txt

reboot
