#!/usr/bin/env bash

# Enable other components of main repo
sed -r -i 's/^deb(.*)$/deb\1 contrib/g' /etc/apt/sources.list
sed -r -i 's/^deb(.*)$/deb\1 non-free/g' /etc/apt/sources.list
apt-get update -y

# Install dependencies for building CoreLib
apt-get install -y \
    libserial-dev \
    libgstreamer1.0-dev \
    libopencv-dev \
    libasio-dev \
    liblgpio-dev