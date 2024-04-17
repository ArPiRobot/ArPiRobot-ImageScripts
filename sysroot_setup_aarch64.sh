#!/usr/bin/env bash

apt-get update -y
apt-get install -y \
    libserial-dev \
    libgstreamer1.0-dev \
    libopencv-dev \
    libboost-dev \
    libboost-system-dev \
    libserialport-dev

# pigpio and lgpio are not available in debian repos
sudo apt-get install -y wget swig python3-dev python3-setuptools
wget https://github.com/joan2937/lg/archive/refs/tags/v0.2.2.tar.gz
tar --extract --gzip -f v0.2.2.tar.gz
cd lg-0.2.2
make
sudo make install
cd ..
rm -rf lg-0.2.2
wget https://github.com/joan2937/pigpio/archive/refs/tags/v79.tar.gz
tar --extract --gzip -f v79.tar.gz
cd pigpio-79
make
sudo make install
cd ..
rm -rf pigpio-79