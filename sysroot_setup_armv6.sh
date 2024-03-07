#!/usr/bin/env bash


# Add missing repo to bootstrap
echo "deb http://archive.raspberrypi.com/debian/ bookworm main" > /etc/apt/sources.list.d/raspi.list

# Enable other components of main repo
sed -r -i 's/^deb(.*)$/deb\1 contrib/g' /etc/apt/sources.list
sed -r -i 's/^deb(.*)$/deb\1 non-free/g' /etc/apt/sources.list
sed -r -i 's/^deb(.*)$/deb\1 rpi/g' /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv 82B129927FA3303E
apt-get update -y

# Install dependencies for building CoreLib
apt-get install -y \
    libserial-dev \
    libgstreamer1.0-dev \
    libopencv-dev \
    libasio-dev \
    liblgpio-dev