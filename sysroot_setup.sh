#!/usr/bin/env bash

# Install dependencies for building CoreLib
apt-get update -y
apt-get install -y \
    libserial-dev
    libgstreamer1.0-dev \
    libopencv-dev \
    libasio-dev \
    liblgpio-dev