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

# Don't update these. Causes issues.
# apt-mark hold initramfs-tools
# apt-mark hold flash-kernel
# apt-mark hold linux-firmware

apt-get -y update
apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef upgrade
dpkg --configure -a


# Packages have now changed. Need to manually make update-initramfs and flash-kernel work
update-initramfs -c -k all
flash-kernel --machine 'Raspberry Pi 4 Model B'

# Enable flash-kernel hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools
chmod +x /etc/initramfs/post-update.d/flash-kernel