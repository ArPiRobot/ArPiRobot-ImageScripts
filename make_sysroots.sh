#!/usr/bin/env bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root";
    exit 1
fi

which debootstrap > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Install debootstrap"
    exit 1
fi

if [ $# -ne 2 ]; then
    echo "Usage: make_sysroots.sh version_codename sysroot_version"
    exit 1
fi

codename="$1"
ver="$2"

BUILDDIR="$(dirname "$0")"/build-sysroot
mkdir -p $BUILDDIR
cd $BUILDDIR

# armv6 chroot is based on raspbian not debian b/c debian armhf is armv7 but Pi zero is armv6 w/ hard float
rm -rf ./bootstrap-armv6
debootstrap --arch=armhf --variant=buildd $codename ./bootstrap-armv6 http://raspbian.raspberrypi.org/raspbian/
cp "$(dirname "$0")/sysroot_setup.sh" ./bootstrap-armv6/setup.sh
chmod +x ./bootstrap-armv6/setup.sh
chroot ././bootstrap-armv6 /setup.sh
rm -rf ./sysroot-armv6
mkdir ./sysroot-armv6
../sysroot-from-root.sh ./bootstrap-armv6 ./sysroot-armv6
cd ./sysroot-armv6
echo -n "sysroot/armv6" > what.txt
echo -n "$ver" > version.txt
rm -f ../sysroot-armv6.tar
rm -f ../sysroot-armv6.tar.gz
tar -cvf ../sysroot-armv6.tar *
gzip ../sysroot-armv6.tar
cd ..
rm -rf ./sysroot-armv6
rm -rf ./bootstrap-armv6

# aarch64 chroot is based on normal debian
rm -rf ./bootstrap-aarch64
sudo debootstrap --arch=arm64 --variant=buildd $codename ./bootstrap-aarch64
cp "$(dirname "$0")/sysroot_setup.sh" ./bootstrap-aarch64/setup.sh
chmod +x ./bootstrap-aarch64/setup.sh
chroot ././bootstrap-aarch64 /setup.sh
rm -rf ./sysroot-aarch64
mkdir ./sysroot-aarch64
../sysroot-from-root.sh ./bootstrap-aarch64 ./sysroot-aarch64
cd ./sysroot-aarch64
echo -n "sysroot/aarch64" > what.txt
echo -n "$ver" > version.txt
rm -f ../sysroot-aarch64.tar
rm -f ../sysroot-aarch64.tar.gz
tar -cvf ../sysroot-aarch64.tar *
gzip ../sysroot-aarch64.tar
cd ..
rm -rf ./sysroot-aarch64
rm -rf ./bootstrap-aarch64

