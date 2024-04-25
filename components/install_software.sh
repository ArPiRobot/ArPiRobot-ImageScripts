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


# General system tools
# Some are expected / required by dt- scripts
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    git \
    sysstat \
    dos2unix \
    iperf3

# Python and packages required by CoreLib
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-setuptools-scm \
    python3-wheel \
    python3-opencv

# CoreLib dependencies
# Note: libasound2 is used to play audio with miniaudio
#       not a linked dependency, but used to allow audio playback
# ffmpeg is invoked via CLI by corelib to write to rtsp server
# due to some fun...issues... with gstreamer's element interacting with 
# rpi's v4l2m2m encoders
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    libasound2 \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-base-apps \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-alsa \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-gl \
    gstreamer1.0-rtsp \
    libopencv-*406 \
    ffmpeg \
    libboost-system1.74.0 \
    libserialport0


# Get architecture of an ELF binary
function binarch(){
    printf "$(readelf -h $1 | grep Machine: | sed -r 's/\s+Machine:\s+//g')"
}

# RTSP server used for camera streams
arch=$(binarch $(which python3))
mkdir /opt/mediamtx
if [ "$arch" = "ARM" ]; then
    wget https://github.com/bluenviron/mediamtx/releases/download/v1.7.0/mediamtx_v1.7.0_linux_armv6.tar.gz -O mediamtx.tar.gz
elif [ "$arch" = "AArch64" ]; then
    wget https://github.com/bluenviron/mediamtx/releases/download/v1.7.0/mediamtx_v1.7.0_linux_arm64v8.tar.gz -O mediamtx.tar.gz
else
    echo "Unknown architecture. Cannot install mediamtx." && exit 1
fi
tar -C /opt/mediamtx --extract --gzip -f mediamtx.tar.gz
rm mediamtx.tar.gz
cp "$DIR/install_software/mediamtx.service" /etc/systemd/system/
systemctl enable mediamtx.service
