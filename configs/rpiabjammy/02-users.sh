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

# Add "arpirobot" user
adduser --disabled-password --gecos "" arpirobot
printf "arpirobot\narpirobot" | passwd arpirobot

# Copy all groups of default user
for i in "tty disk dialout sudo audio video plugdev games users systemd-journal input netdev" ; do
    addgroup arpirobot $i
done

# Setting root password
printf "notdefault\nnotdefault" | passwd root

# Allow passwordless sudo for arpirobot
echo "arpirobot ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_arpirobot-nopasswd

