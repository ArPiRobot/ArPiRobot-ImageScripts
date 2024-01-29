#!/usr/bin/env bash

function exit_trap(){
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "\"${last_command}\" command failed with exit code $ec."
    fi
}
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap exit_trap EXIT

# Create connection for hotspot
nmcli connection add type wifi ifname $ifname con-name RobotAP ssid ArPiRobot-RobotAP

# Configure as access point using 2.4GHz 
nmcli connection modify RobotAP 802-11-wireless.mode ap
nmcli connection modify RobotAP 802-11-wireless.band bg

# Configure password
nmcli connection modify RobotAP wifi-sec.key-mgmt wpa-psk
nmcli connection modify RobotAP wifi-sec.psk arpirobot123

# Configure IP address
nmcli connection modify RobotAP ipv4.method shared
nmcli connection modify RobotAP ipv4.addresses 192.168.10.1/24
nmcli connection modify RobotAP ipv6.method disabled

# Enable hotspot at boot
nmcli connection modify RobotAP connection.autoconnect yes

