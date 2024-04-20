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

# Enable UART console
printf "enable_uart=1\n" >> /boot/firmware/config.txt

# Remove console=tty1 so that systemd output is shown on uart console
sudo sed -i 's/ console=tty1//g' /boot/firmware/cmdline.txt

# Enable hardware interfaces
raspi-config nonint do_spi 0
raspi-config nonint do_i2c 0
raspi-config nonint do_ssh 0
raspi-config nonint do_camera 0

# Write a file indicating which I2C interface should be used by the CoreLib
# by default on this board. This is allows easier use of hats from the CoreLib
# by not having to specify a specifc I2C bus number, improving portability
# of code across different SBCs
echo "1" > /usr/local/arpirobot_default_i2c.txt