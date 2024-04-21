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


# Disable NetworkManager
# Even though it could be used to create a hotspot, this has proven less reliable than just using
# hostapd (specifically on some orange pi hardware). Thus, configuring /etc/network/interfaces along
# with dnsmasq and hostapd manually
systemctl disable NetworkManager.service
systemctl mask NetworkManger.service

# Install required packages
DEBIAN_FRONTEND=noninteractive apt-get -y install dnsmasq hostapd

# Write hostpad config files
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf << 'EOF'
interface=wlan0
ssid=ArPiRobot-RobotAP
hw_mode=g
channel=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=arpirobot123
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
wmm_enabled=1
EOF
printf 'DAEMON_CONF="/etc/hostapd/hostapd.conf"\n' >> /etc/default/hostapd

# Write dnsmasq config file
cat > /etc/dnsmasq.conf << 'EOF'
interface=wlan0
dhcp-range=192.168.10.2,192.168.10.20,255.255.255.0,24h
domain=local
address=/ArPiRobot-Robot.local/192.168.10.1
EOF

# Configure static IP in /etc/network/interfaces
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

allow-hotplug wlan0
iface wlan0  inet static
    address 192.168.10.1
    netmask 255.255.255.0
EOF


# Enable services
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Default to unset regulatory domain
# User can change in deploy tool
echo "options cfg80211 ieee80211_regdom=00" > /etc/modprobe.d/cfg80211_regdomain.conf