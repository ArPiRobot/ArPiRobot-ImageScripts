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


# UART console enabled by default on this board

# Enable hardware interfaces
echo "overlays=i2c2-m1 i2c3-m0 spi3-m0-cs0-spidev uart2-m0" >> /boot/orangepiEnv.txt

# Write a file indicating which I2C interface should be used by the CoreLib
# by default on this board. This is allows easier use of hats from the CoreLib
# by not having to specify a specifc I2C bus number, improving portability
# of code across different SBCs
echo "2" > /usr/local/arpirobot_default_i2c.txt

# Increase default gpu memory on lower ram devices
# Necessary for v4l2m2m encoders to work properly
echo "gpu_mem=16" >> /boot/firmware/config.txt
echo "gpu_mem_256=76" >> /boot/firmware/config.txt
echo "gpu_mem_512=76" >> /boot/firmware/config.txt
echo "gpu_mem_1024=76" >> /boot/firmware/config.txt
