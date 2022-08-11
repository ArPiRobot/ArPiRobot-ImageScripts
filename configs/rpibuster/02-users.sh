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

# Copy all groups of default "pi" user
for i in `grep -E "(:|,)pi(:,|$)" /etc/group|cut -f1 -d:` ; do
    addgroup arpirobot $i
    print_if_fail
done

# Delete default "pi" user
deluser pi
rm -r /home/pi
rm /etc/sudoers.d/010_pi-nopasswd

# Setting root password
printf "notdefault\nnotdefault" | passwd root

# Allow passwordless sudo for arpirobot
echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_arpirobot-nopasswd
