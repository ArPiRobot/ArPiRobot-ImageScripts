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
echo "ArPiRobot-Robot" > /etc/hostname  >> $LOGFILE 2>&1
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
printf '# KEYBOARD CONFIGURATION FILE\n# Consult the keyboard(5) manual page.\nXKBMODEL="pc105"\nXKBLAYOUT="us"\nXKBVARIANT=""\nXKBOPTIONS=""\n\nBACKSPACE="guess"\n' | tee  /etc/default/keyboard  >> $LOGFILE 2>&1
print_status


printf "Enabling SSH, SPI, and I2C..."
raspi-config nonint do_spi 1  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_i2c 1  >> $LOGFILE 2>&1
print_if_fail
raspi-config nonint do_ssh 1  >> $LOGFILE 2>&1
print_status

printf "Cloning ArPiRobot Raspbian tools repo..."
git clone git@github.com:MB3hel/ArPiRobot-RaspbianTools.git /home/pi/ArPiRobot-RaspbianTools >> $LOGFILE 2>&1
print_status

printf "Installing raspbian tools..."
cd /home/pi/ArPiRobot-RaspbianTools>> $LOGFILE 2>&1
print_if_fail
chmod +x ./install.sh>> $LOGFILE 2>&1
print_if_fail
./install.sh
print_status

printf "Installing other required software..."
apt-get -y install hostapd dnsmasq >> $LOGFILE 2>&1
print_status

printf "Setting up to create virtual adapter on boot..."
sed -i 's/exit 0//g' /etc/rc.local >> $LOGFILE 2>&1
print_if_fail
printf "/usr/local/bin/wirelessadd.sh\n/usr/local/bin/wirelessinit.sh\n\nexit 0" | tee -a /etc/rc.local >> $LOGFILE 2>&1
print_status

printf "Writing dnsmasq config file..."
printf "interface=lo,ap0\nno-dhcp-interface=lo,wlan0\nbind-interfaces\nserver=8.8.8.8\ndomain-needed\nbogus-priv\ndhcp-range=192.168.10.50,192.168.10.150,12h\naddress=/ArPiRobot-Robot.lan/192.168.10.1\n" | tee /etc/dnsmasq.conf >> $LOGFILE 2>&1
print_status

printf "Writing hostapd config file..."
printf "ctrl_interface=/var/run/hostapd\nctrl_interface_group=0\ninterface=ap0\ndriver=nl80211\nssid=ArPiRobot-RobotAP\nhw_mode=g\nchannel=11\nwmm_enabled=0\nmacaddr_acl=0\nauth_algs=1\nwpa=2\nwpa_passphrase=arpirobot123\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP CCMP\nrsn_pairwise=CCMP" | tee /etc/hostapd/hostapd.conf  >> $LOGFILE 2>&1
print_if_fail
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="/etc/hostapd/hostapd.conf"/g' /etc/default/hostapd >> $LOGFILE 2>&1
print_status

printf "Fixing dnsmasq on readonly filesystem..."
echo "tmpfs /var/lib/misc tmpfs nosuid,nodev 0 0" | tee -a /etc/fstab >> $LOGFILE 2>&1
print_status

printf "Adding client network id string..."
sed -i 's/}//g' /etc/wpa_supplicant/wpa_supplicant.conf >> $LOGFILE 2>&1
print_if_fail
printf '\tid_str="AP1"\n}\n' | tee -a /etc/wpa_supplicant/wpa_supplicant.conf
print_status

printf "Configuring interfaces..."
printf "auto lo\nauto ap0\nauto wlan0\niface lo inet loopback\n\nallow-hotplug ap0\niface ap0 inet static\n    address 192.168.10.1\n    netmask 255.255.255.0\n    hostapd /etc/hostapd/hostapd.conf\n\nallow-hotplug wlan0\niface wlan0 inet manual\n    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf\niface AP1 inet dhcp" | tee -a /etc/network/interfaces >> $LOGFILE 2>&1
print_status


################################################################################
# Restart
################################################################################

printf "The system will now reboot. Once rebooted run stage4.sh as root.\nPress enter to reboot now..."
read n

echo "stage3" > /root/last_setup_stage.txt

reboot
