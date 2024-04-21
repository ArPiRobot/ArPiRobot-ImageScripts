#!/usr/bin/env bash
function exit_trap(){
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "\"${last_command}\" command failed with exit code $ec." >&2
    fi
}
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap exit_trap EXIT
DIR="$(dirname "$0")"

# Write dnsmasq config file
cat >> /etc/dnsmasq.conf << 'EOF'

interface=eth0
dhcp-range=192.168.11.2,192.168.11.20,255.255.255.0,24h
domain=local
address=/ArPiRobot-Robot.local/192.168.11.1
EOF

# Configure static IP in /etc/network/interfaces
cat >> /etc/network/interfaces << 'EOF'

allow-hotplug eth0
iface eth0  inet static
    address 192.168.11.1
    netmask 255.255.255.0
EOF