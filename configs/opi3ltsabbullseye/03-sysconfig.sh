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

# Disable first boot auto login, root password change, and system configuration
rm /root/.not_logged_in_yet
rm /etc/systemd/system/getty@.service.d/override.conf
rm /etc/systemd/system/serial-getty@.service.d/override.conf

# Set hostname
echo "ArPiRobot-Robot" | tee /etc/hostname
sed -i "s/rpi4b/ArPiRobot-Robot/g" /etc/hosts

# Set locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

# Set keyboard layout
cat > /etc/default/keyboard << 'EOF'
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# Enable ssh server
systemctl enable ssh

# Enable hardware interfaces
sed -i '/^overlays=/d' /boot/armbianEnv.txt
printf "overlays=i2c0 i2c1 spi-spidev uart1 uart2 uart3\n" >> /boot/armbianEnv.txt
printf "param_spidev_spi_bus=0\n" >> /boot/armbianEnv.txt

# Setup custom systemd tartet & service & script to allow running commands at end of boot process
cat > /etc/systemd/system/custom.target << 'EOF'
[Unit]
Description=Custom Target
Requires=multi-user.target
After=multi-user.target
EOF
ln -sf /etc/systemd/system/custom.target /etc/systemd/system/default.target
cat > /etc/systemd/system/lastcommands.service << 'EOF'
[Unit]
Description=Run final boot commands
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/last_boot_scripts.sh

[Install]
WantedBy=custom.target
EOF
systemctl enable lastcommands.service
cat > /usr/local/bin/last_boot_scripts.sh << 'EOF'
#!/usr/bin/env bash

# During first boot, wait for armbian-firstrun to finish before running these scripts
# process name is truncated to armbian-firstru
while [ $(pgrep armbian-firstru | wc -l) -gt 0 ]; do
    echo "Waiting for armbian-firstrun to finish..."
    sleep 1;
done


files=$(find /usr/local/last_boot_scripts/ -name "*.sh" | sort)
for file in $files; do
    echo "Running $file"
    bash "$file"
done
EOF
chmod +x /usr/local/bin/last_boot_scripts.sh
mkdir -p /usr/local/last_boot_scripts/


# armbian-firstrun service handles ssh key generation
