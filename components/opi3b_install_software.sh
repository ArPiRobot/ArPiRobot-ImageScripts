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
    libcamera0.0.3 \
    gstreamer1.0-libcamera \
    libcamera-tools

# pigpio and lgpio are not available in debian repos
apt-get install -y wget swig python3-dev python3-setuptools
wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz
tar --extract --gzip -f v0.2.2.tar.gz
cd lg-0.2.2
make
make install
cd ..
rm -rf lg-0.2.2
wget https://github.com/joan2937/pigpio/archive/refs/tags/v79.tar.gz
tar --extract --gzip -f v79.tar.gz
cd pigpio-79
make
make install
cd ..
rm -rf pigpio-79