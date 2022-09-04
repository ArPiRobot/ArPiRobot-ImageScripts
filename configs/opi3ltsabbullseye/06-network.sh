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


# Doesn't work right in chroot
chmod -x /etc/kernel/postinst.d/initramfs-tools

# Install required software
apt-get -y install hostapd dnsmasq

# Packages have now changed. Need to manually update-initramfs
update-initramfs -c -k all

# Enable hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools

# Enable services
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Write hostpad config files
mkdir -p /etc/hostpad
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

# Fix dnsmasq / systemd-resolved conflict
printf "DNSStubListener=no\n" >> /etc/systemd/resolved.conf

# Configure static IPs
cat > /etc/network/interfaces << 'EOF'
# Loopback
auto lo
iface lo inet loopback
 
# Ethernet
auto eth0
iface eth0  inet static
    address 192.168.11.1
    netmask 255.255.255.0

# WiFi
auto wlan0
iface wlan0  inet static
    address 192.168.10.1
    netmask 255.255.255.0
EOF

# Script to fix wireless on first boot
# cat > /usr/local/last_boot_scripts/10-fix-wireless.sh << 'EOF'
# #!/usr/bin/env bash
# rfkill unblock wlan
# systemctl daemon-reload
# systemctl restart hostapd
# systemctl restart dnsmasq
# rm /usr/local/last_boot_scripts/10-fix-wireless.sh

# # For some reason, despite sleeps, waiting for processes, etc
# # The AP will not work until hostapd is restarted from a login session
# # Or until the system reboots
# # So, to fix wifi, reboot the system on the first boot
# # Yes this is a dumb solution, but it works...
# sleep 3
# reboot
# EOF
# chmod +x /usr/local/last_boot_scripts/10-fix-wireless.sh