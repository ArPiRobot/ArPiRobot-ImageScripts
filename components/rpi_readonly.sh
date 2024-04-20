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


# Options useful for readonly filesystem
printf "$(head -1 /boot/firmware/cmdline.txt) fastboot noswap rfkill.default_state=1" > /boot/firmware/cmdline.txt

# Write board-specific dt-ro.sh and dt-rw.sh
cat << 'EOF' > /usr/local/bin/dt-ro.sh
#!/bin/bash
sudo mount -o ro,remount /
sudo mount -o ro,remount /boot/firmware
EOF
chmod +x /usr/local/bin/dt-ro.sh

cat << 'EOF' > /usr/local/bin/dt-rw.sh
#!/bin/bash
sudo mount -o rw,remount /
sudo mount -o rw,remount /boot/firmware
EOF
chmod +x /usr/local/bin/dt-rw.sh