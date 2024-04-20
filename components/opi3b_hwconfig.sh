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
# The enabled I2C and SPI devices are on pins matching Raspberry Pi 3B
# thus hats should work as expected
# Note: Do not enable the uart2-m0 overlay. uart2_m0 is used for the
# debug console, but enabling the overlay disables exposing that uart
# as ttyFIQ0 for debug console
# This matches behavior of RPi images where corresponding pins on 40 pin
# header are used for UART
echo "overlays=i2c2-m1 i2c3-m0 spi3-m0-cs0-spidev" >> /boot/orangepiEnv.txt

# Write a file indicating which I2C interface should be used by the CoreLib
# by default on this board. This is allows easier use of hats from the CoreLib
# by not having to specify a specifc I2C bus number, improving portability
# of code across different SBCs
echo "2" > /usr/local/arpirobot_default_i2c.txt

# Write a file indicating which SPI interface should be used by the CoreLib
# by default on this board. This is allows easier use of hats from the CoreLib
# by not having to specify a specifc SPI bus number, improving portability
# of code across different SBCs
echo "3" > /usr/local/arpirobot_default_spi.txt

# Enable console earlier in kernel boot (before getty service starts)
sed -i '/^extraargs=/ s/$/ console=ttyFIQ0/' /boot/orangepiEnv.txt