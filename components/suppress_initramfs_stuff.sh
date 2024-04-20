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


# Doesn't work right in chroot
chmod -x /etc/kernel/postinst.d/initramfs-tools

# Don't update these. Causes issues.
apt-mark hold initramfs-tools
apt-mark hold flash-kernel
apt-mark hold orangepi-firmware