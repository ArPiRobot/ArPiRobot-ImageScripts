#!/usr/bin/env bash

# Add missing repo to bootstrap
echo "deb http://archive.raspberrypi.com/debian/ bookworm main" > /etc/apt/sources.list.d/raspi.list

# Enable other components of main repo
sed -r -i 's/^deb(.*)$/deb\1 contrib/g' /etc/apt/sources.list
sed -r -i 's/^deb(.*)$/deb\1 non-free/g' /etc/apt/sources.list
sed -r -i 's/^deb(.*)$/deb\1 rpi/g' /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv 82B129927FA3303E
apt-get update -y


apt-get install -y \
    libserial-dev \
    libgstreamer1.0-dev \
    libboost-dev \
    libboost-system-dev \
    liblgpio-dev \
    libpigpio-dev \
    libserialport-dev \
    libpigpiod-if-dev \
    libopencv-calib3d-dev \
    libopencv-contrib-dev \
    libopencv-core-dev \
    libopencv-dnn-dev \
    libopencv-features2d-dev \
    libopencv-flann-dev \
    libopencv-imgcodecs-dev \
    libopencv-imgproc-dev \
    libopencv-ml-dev \
    libopencv-objdetect-dev \
    libopencv-photo-dev \
    libopencv-shape-dev \
    libopencv-stitching-dev \
    libopencv-superres-dev \
    libopencv-video-dev \
    libopencv-videoio-dev \
    libopencv-videostab-dev \
    libopencv-viz-dev



