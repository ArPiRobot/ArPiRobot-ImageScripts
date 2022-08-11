# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi: 3B(+), 3A(+), 4B, Zero W, Zero 2 W
    - RasPiOS Lite Buster (10) 32-bit (`rpibuster`)
    - [Download](https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/)

<!--
- Raspberry Pi: 3B(+), 3A(+), 4B, Zero 2 W
    - Ubuntu Server Jammy (22.04) 64-bit (`scripts_rpijammy`)
    - [Download](https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-preinstalled/current/)
-->


## Using Scripts to Make an Image

- Download the base image
- Increase the base image size using dd
- Setup a loopback device
- Grow the base image root partition using gparted (or any other method)
- Mount base image root on /mnt/img-chroot
- Mount other partitions according to base image's fstab
- Bind mount proc, sys, dev
- Install qemu-user-static
- Chroot into /mnt/img-chroot
    - Install git
    - Clone this repository
    - Run make_image.py [config] [version]
    - Let all scripts run (address errors if any)
    - Exit chroot
- Unmount bind mounted things
- Unmount non root partitions
- Unmount root partition
- Shrink partition with gparted (or any other method)
- Use fdisk & truncate to shrink image
- Gzip the image file and rename it in the format `ArPiRobot-[version]-[config].img.gz`


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
