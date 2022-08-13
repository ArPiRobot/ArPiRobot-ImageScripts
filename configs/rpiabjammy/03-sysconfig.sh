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

# Enable UART console
sed -i 's/# enable_uart=1/enable_uart=1/g' /boot/firmware/config.txt
sed -i 's/console=tty1/console=ttyS0,115200/g' /boot/firmware/cmdline.txt

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

# Patching raspi-config
if ! grep -q /boot/firmware/ /usr/bin/raspi-config; then
    sed -i 's/\/boot\//\/boot\/firmware\//g' /usr/bin/raspi-config
fi

# Enable hardware interfaces
raspi-config nonint do_spi 0
raspi-config nonint do_i2c 0
raspi-config nonint do_ssh 0
raspi-config nonint do_camera 0

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
files=$(find /usr/local/last_boot_scripts/ -name "*.sh" | sort)
for file in $files; do
    bash "$file"
done
EOF
chmod +x /usr/local/bin/last_boot_scripts.sh
mkdir -p /usr/local/last_boot_scripts/


# armbian-firstrun service handles ssh key generation
