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


# Install required software from system repos
DEBIAN_FRONTEND=noninteractive apt-get -y install git \
    dos2unix \
    sysstat \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-setuptools-scm \
    python3-wheel \
    openjdk-8-jdk-headless \
    libasound2-dev \
    iperf3 \
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
    python3-gi \
    python3-gst-1.0 \
    gstreamer1.0-gl \
    gstreamer1.0-rtsp