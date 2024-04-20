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

# Disable auto login
# This script is included in orangepi image. Not sure if it's an armbian thing or an orangepi addition
auto_login_cli.sh -d

# Rename orangepi user to arpirobot
# We could create a new user and add groups, but this is just easier
usermod --login arpirobot --move-home --home /home/arpirobot orangepi

# Change password
printf "arpirobot\narpirobot" | passwd arpirobot

# Allow passwordless sudo for arpirobot
echo "arpirobot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_arpirobot-nopasswd
