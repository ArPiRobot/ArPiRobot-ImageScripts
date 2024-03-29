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


# Install required software
apt-get -y install hostapd dnsmasq

# Enable services
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Write country code to wpa_supplicant.conf to allow rfkill unblock to work
printf "\ncountry=US\n" >> /etc/wpa_supplicant/wpa_supplicant.conf

# Write hostpad config files
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf << 'EOF'
country_code=US
ieee80211d=1
interface=wlan0
ssid=ArPiRobot-RobotAP
hw_mode=g
channel=6
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

# Write dhcpcd config file
cat >> /etc/dhcpcd.conf << 'EOF'
interface wlan0
    static ip_address=192.168.10.1/24
    nohook wpa_supplicant
interface eth0
    static ip_address=192.168.11.1/24
EOF


# Script to fix wireless on first boot
cat > /usr/local/last_boot_scripts/10-fix-wireless.sh << 'EOF'
#!/usr/bin/env bash
rfkill unblock wlan
systemctl daemon-reload
systemctl restart hostapd
systemctl restart dnsmasq
systemctl restart dhcpcd
rm /usr/local/last_boot_scripts/10-fix-wireless.sh
EOF
chmod +x /usr/local/last_boot_scripts/10-fix-wireless.sh
