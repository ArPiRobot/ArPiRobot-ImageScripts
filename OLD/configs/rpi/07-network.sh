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

# Note: Can't use nmcli in chroot, thus write a config file instead
cat > /etc/NetworkManager/system-connections/RobotAP.nmconnection << 'EOF'
[connection]
id=RobotAP
uuid=b1bbea3e-9954-4827-b6ee-b0bc244d48a9
type=wifi
interface-name=wlan0
autoconnect=true

[wifi]
band=bg
channel=0
mode=ap
ssid=ArPiRobot-RobotAP

[wifi-security]
key-mgmt=wpa-psk
psk=arpirobot123

[ipv4]
address1=192.168.10.1/24
method=shared

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]
EOF
chmod 600 /etc/NetworkManager/system-connections/RobotAP.nmconnection

# Default to unset regulatory domain
echo "options cfg80211 ieee80211_regdom=00" > /etc/modprobe.d/cfg80211_regdomain.conf