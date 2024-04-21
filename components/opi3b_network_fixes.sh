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


# Auto channel search does not work on this board
sed -i 's/channel=0/channel=6/g' /etc/hostapd/hostapd.conf

# Ethernet is end1 not eth0 on this board
sed -i 's/interface=eth0/interface=end1/g' /etc/dnsmasq.conf
sed -i 's/eth0/end1/g' /etc/network/interfaces