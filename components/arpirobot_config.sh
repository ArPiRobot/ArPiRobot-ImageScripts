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


# Scripts used by deploy tool
for script in "$DIR/arpirobot_config/scripts"/*; do
    cp "$script" /usr/local/bin/
    chmod +x /usr/local/bin/$(basename "$script")
done

# Service to start robot program
cp "$DIR/arpirobot_config/services/arpirobot-program.service" /etc/systemd/system/
systemctl enable arpirobot-program.service

# Create directory for robot program
mkdir -p /home/arpirobot/arpirobot
chown arpirobot:arpirobot /home/arpirobot/arpirobot
