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

# Packages have now changed. Need to manually update-initramfs
update-initramfs -c -k all

# Enable hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools