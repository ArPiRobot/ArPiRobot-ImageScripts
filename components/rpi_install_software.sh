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


# Libcamera stuff
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libcamera0.2 \
    gstreamer1.0-libcamera \
    rpicam-apps-lite

# pigpio and lgpio are available in system repos, so no need to build from source
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    liblgpio1 \
    libpigpio1 \
    libpigpiod-if-dev