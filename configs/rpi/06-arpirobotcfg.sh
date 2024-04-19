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

# Scripts used by deploy tool
DIR="$(dirname "$0")"
cp "$DIR/../../common/scripts"/* /usr/local/bin/
cp "$DIR/scripts"/* /usr/local/bin/

# Service to start robot program
cp "$DIR/../../common/services/arpirobot-program.service" /etc/systemd/system/
systemctl enable arpirobot-program.service

# Create directory for robot program
mkdir -p /home/arpirobot/arpirobot
chown arpirobot:arpirobot /home/arpirobot/arpirobot
