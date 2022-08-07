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
# script:      04_networking.sh
# description: Setup networking (ethernet and wireless)
# author:      Marcus Behel
################################################################################

# Initialization
DIR=$(realpath $(dirname "$0"))         # get directory of this script
ORIG_CWD=$(pwd)                         # store original working directory
cd "$DIR"                               # cd to script directory
source "$DIR/../99_functions.sh"        # source helper functions file
check_root                              # ensure running as root

# Body of the script
{
    script=$(basename "$0")
    lastscript=$(read_last_stage)
    echo "Running \"${script}\":"
    echo "Last run script: \"${lastscript}\"."
    echo "--------------------------------------------------------------------------------"

    # Code goes here
    # TODO: Setup ethernet for static 192.168.11.1

    echo "Installing required software for network configuration..."
    apt-get -y install hostapd dnsmasq
    print_status

    echo "Configuring hostapd to start on boot..."
    systemctl unmask hostapd
    print_if_fail
    systemctl enable hostapd
    print_status

    echo "Unblocking WiFi..."
    sudo rfkill unblock wlan
    print_status_noexit

    echo "Writing dnsmasq config file..."
    printf "interface=wlan0\ndhcp-range=192.168.10.2,192.168.10.20,255.255.255.0,24h\ndomain=local\naddress=/ArPiRobot-Robot.local/192.168.10.1" | tee /etc/dnsmasq.conf
    print_status

    echo "Writing hostapd config file..."
    printf "country_code=US\nieee80211d=1\ninterface=wlan0\nssid=ArPiRobot-RobotAP\nhw_mode=g\nchannel=6\nmacaddr_acl=0\nauth_algs=1\nignore_broadcast_ssid=0\nwpa=2\nwpa_passphrase=arpirobot123\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP\nwmm_enabled=1\n" | tee /etc/hostapd/hostapd.conf
    print_if_fail
    printf 'DAEMON_CONF="/etc/hostapd/hostapd.conf"\n' | tee -a /etc/default/hostapd
    print_status

    echo "Configuring dhcpcd..."
    printf "interface wlan0\n    static ip_address=192.168.10.1/24\n    nohook wpa_supplicant\ninterface eth0\n    static ip_address=192.168.11.1/24" | tee -a /etc/dhcpcd.conf
    print_status

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file
