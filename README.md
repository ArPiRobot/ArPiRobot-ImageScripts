# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

Also includes scripts to build a cross compilation sysroot using debootstrap.

## Configurations

Each configuration is designed for a certain base image (usually the official OS image from the board vendor). The base images the config was designed for are listed below.

- Raspberry Pi - All (`rpi`):
    - RasPiOS Lite Bookworm (12) 32-bit
    - [Base Image Downloads](https://www.raspberrypi.com/software/operating-systems/)
    - Base Image Used: `2023-12-11-raspios-bookworm-armhf-lite.img.xz`

- Orange Pi Zero 2W - 1GB and 2GB variants (`opi_zero2w`)
    - Debian Bookworm (12) 64-bit (`opi_zero2w`)
    - [Base Image Downloads](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-2W.html)
    - Base Image Used: `Orangepizero2w_1.0.0_debian_bookworm_server_linux6.1.31.7z` (tested with image for the 1GB/2GB boards, images for the 1.5GB and 4GB will probably work too)

- Orange Pi 3B:
    - Debian Bookworm (12) 64-bit (`opi_3b`)
    - [Base Image Downloads](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-3B.html)
    - Base Image Used: `Orangepi3b_1.0.4_debian_bookworm_server_linux5.10.160.7z`


## Using Scripts to Make an Image

*Note: Must be done on a Linux system.*

- Install qemu-user-static
- Download the base image
- Increase the base image size using dd (3GB usually good)
    ```sh
    dd if=/dev/zero bs=1MiB count=3072 >> file_name.img
    ```
- Setup a loopback device (sudo losetup -f -P --show)
- Grow the base image root partition using gparted (or any other method)
- Mount base image root
- Mount other partitions according to base image's fstab
- Bind mount proc, sys, dev
    ```sh
    mount -t proc /proc root/proc
    mount -t sysfs /sys root/sys
    mount --rbind /dev root/dev
    mount --make-rslave root/dev
    ```
- Copy host system's resolv.conf contents (if needed). Don't copy actual file to avoid overwriting symlinks on some systems.
- Chroot into mounted image
    - Install git and python3
    - Clone this repository
    - Run make_image.py [config] [version]
    - Let all scripts run (address errors if any)
    - Exit chroot
- Copy off the log and delete cloned repo from mounted root directory
- Unmount bind mounted things
    ```sh
    umount -R root/dev
    umount root/sys
    umount root/proc
    ```
- Unmount non root partitions
- Unmount root partition
- Shrink partition with gparted (or any other method)
- Detach the loopback device
- Use fdisk & truncate to shrink image
    ```sh
    fdisk -l image_name.img
    # Multiply end of last partition + 1 by sector size to get size
    # Note that if the system uses a GPT partition table add 34 not 1(33 for backup gpt table after shrink)
    truncate --size=size_here image_name.img
    # If using GPT parition table, use gdisk to rewrite headers and tables (w command) after
    ```
- xzip the image file and rename it in the format `ArPiRobot-[version]-[config].img.xz`
    ```sh
    xz -z image_name.img -v -T 0
    ```

## Using Scripts to Make a Sysroot

*Note: Must be done on a Linux system.*

*Note: This does not run on an image file. Just on any linux system with debootstrap and qemu-user-static installed.*

```sh
# make_sysroots.sh [codename] [sysroot_version]
sudo ./make_sysroots.sh bookworm 1.1.0
```

This will create sysroot tarballs for each supported architecture in `build-sysroot/`.

## License

```
ArPiRobot-ImageScripts is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Softwarel Foundation, either version 3 of the License, or
(at your option) any later version.

ArPiRobot-ImageScripts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ArPiRobot-ImageScripts.  If not, see <https://www.gnu.org/licenses/>.
```
