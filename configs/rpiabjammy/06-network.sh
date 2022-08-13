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


# Disable flash-kernel hooks because they don't work right in chroot
# See process used by https://github.com/armbian/build/blob/master/extensions/flash-kernel.sh
chmod -x /etc/kernel/postinst.d/initramfs-tools
chmod -x /etc/initramfs/post-update.d/flash-kernel

# Install required software
apt-get -y install hostapd dnsmasq

# Packages have now changed. Need to manually make update-initramfs and flash-kernel work
update-initramfs -c -k all
flash-kernel --machine 'Raspberry Pi 4 Model B'

# Enable flash-kernel hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools
chmod +x /etc/initramfs/post-update.d/flash-kernel

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

# Configure netplan
rm /etc/netplan/armbian-default.yaml
cat > /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      optional: true
      addresses: [192.168.11.1/24]
    wlan0:
      dhcp4: false
      dhcp6: false
      optional: true
      addresses: [192.168.10.1/24]
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