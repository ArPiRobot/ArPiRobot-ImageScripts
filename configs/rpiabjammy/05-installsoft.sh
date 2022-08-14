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


# Get architecture of an ELF binary
function binarch(){
    printf "$(readelf -h $1 | grep Machine: | sed -r 's/\s+Machine:\s+//g')"
}

# Disable flash-kernel hooks because they don't work right in chroot
# See process used by https://github.com/armbian/build/blob/master/extensions/flash-kernel.sh
chmod -x /etc/kernel/postinst.d/initramfs-tools
chmod -x /etc/initramfs/post-update.d/flash-kernel

# Install required software from system repos
apt-get -y install git \
    openssh-server \
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
    gstreamer1.0-rtsp \
    libboost-dev \
    libgnutls28-dev \
    openssl \
    libtiff5-dev \
    meson \
    python3-jinja2 \
    cmake \
    libglib2.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libjpeg-dev \
    libboost-program-options-dev \
    libdrm-dev \
    libexif-dev \
    libpng-dev

# Packages have now changed. Need to manually make update-initramfs and flash-kernel work
# This is probably unnecessary (especially the flash-kernel part)
update-initramfs -c -k all
flash-kernel --machine 'Raspberry Pi 4 Model B'

# Enable flash-kernel hooks again
chmod +x /etc/kernel/postinst.d/initramfs-tools
chmod +x /etc/initramfs/post-update.d/flash-kernel

# Install ArPiRobot-CameraStreaming
cd /home/arpirobot
git clone https://github.com/ArPiRobot/ArPiRobot-CameraStreaming.git
chown -R arpirobot:arpirobot ArPiRobot-CameraStreaming
cd ArPiRobot-CameraStreaming
chmod +x ./install.sh
./install.sh arpirobot
arch=$(binarch $(which python3))
if [ "$arch" = "ARM" ]; then
    chmod +x ./install_rtsp_server_armv6.sh
    ./install_rtsp_server_armv6.sh arpirobot
elif [ "$arch" = "AArch64" ]; then
    chmod +x ./install_rtsp_server_aarch64.sh
    ./install_rtsp_server_aarch64.sh arpirobot
else
    echo "Unknown architecture. Cannot install rtsp-simple-server."
    exit 1
fi
cd
rm -rf /home/arpirobot/ArPiRobot-CameraStreaming

# Install ArPiRobot-Tools
cd /home/arpirobot
git clone https://github.com/ArPiRobot/ArPiRobot-Tools.git
cd ArPiRobot-Tools
chmod +x ./install.sh
./install.sh arpirobot
cd
rm -rf /home/arpirobot/ArPiRobot-Tools

# Create directory for robot program
mkdir -p /home/arpirobot/arpirobot
chown arpirobot:arpirobot /home/arpirobot/arpirobot

# Build libcamera from source (can't build libcamera-apps with apt repo versions)
pip3 install pyyaml ply
pip3 install --upgrade meson
cd
git clone git://linuxtv.org/libcamera.git
cd libcamera
meson build --buildtype=release -Dpipelines=raspberrypi -Dipas=raspberrypi -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled
ninja -C build -j 4
ninja -C build install
cd
rm -r libcamera

# Build libcamera-apps from source (not available as deb on armbian)
cd
git clone https://github.com/raspberrypi/libcamera-apps.git
cd libcamera-apps
mkdir build
cd build
cmake .. -DENABLE_DRM=1 -DENABLE_X11=0 -DENABLE_QT=0 -DENABLE_OPENCV=0 -DENABLE_TFLITE=0
make -j4
make install
ldconfig
cd
rm -r libcamera-apps