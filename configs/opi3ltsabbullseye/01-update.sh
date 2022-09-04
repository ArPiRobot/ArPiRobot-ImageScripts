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

# Don't update these. Causes issues.
apt-mark hold initramfs-tools
apt-mark hold flash-kernel

apt-get -y update
apt-get -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef upgrade
dpkg --configure -a


# Packages have now changed. Need to manually update-initramfs
update-initramfs -c -k all

# Enable hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools
