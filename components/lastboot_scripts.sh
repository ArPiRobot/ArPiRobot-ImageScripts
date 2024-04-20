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


# Setup custom systemd target & service & script to allow running commands at end of boot process
cp "$DIR/lastboot_scripts/custom.target" /etc/systemd/system/
ln -sf /etc/systemd/system/custom.target /etc/systemd/system/default.target

cp "$DIR/lastboot_scripts/lastcommands.service" /etc/systemd/system/
systemctl enable lastcommands.service

cp "$DIR/lastboot_service/last_boot_scripts.sh" /usr/local/bin/
chmod +x /usr/local/bin/last_boot_scripts.sh
mkdir -p /usr/local/last_boot_scripts/
