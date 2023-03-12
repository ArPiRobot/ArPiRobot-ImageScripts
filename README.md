# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi: 3B(+), 3A(+), 4B, Zero W, Zero 2 W
    - RasPiOS Lite Buster (10) 32-bit (`rpibuster`)
    - [Download](https://downloads.raspberrypi.org/raspios_oldstable_lite_armhf/images/)

- Raspberry Pi: 3B(+), 3A(+), 4B, Zero 2 W
    - Armbian 22.05 w/ Jammy Userspace 64-bit 5.15 kernel (`rpiabjammy`)
    - [Download](https://www.armbian.com/rpi4b/)

- Orange Pi Lite
    - Armbian 22.08 w/ Jammy Userspace 32-bit 5.15 kernel (`opliteabjammy`)
    - [Download](https://www.armbian.com/orange-pi-lite/)

- Orange Pi 3 LTS
    - Armbian 22.08 w/ Bullseye Userspace 64-bit 5.15 kernel (`opi3ltsabbullseye`)
    - *Note: Bullseye userspace used instead of Jammy userspace due to [WiFi issues with Jammy Userspace](https://forum.armbian.com/topic/21697-orangepi-3-lts-armbian-2205-jammy-xfce-cant-connect-with-wifi/)*
    - [Download](https://www.armbian.com/orangepi3-lts/)


## Using Scripts to Make an Image

*Note: Must be done on a Linux system.*

- Install qemu-user-static
- Download the base image
- Increase the base image size using dd (3GB usually good)
    ```sh
    dd if=/dev/zero bs=1MiB count=3072 >> file_name.img
    ```
- Setup a loopback device
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
- Chroot into /mnt/img-chroot
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
    # If using GPT table use gdisk to rewrite backup gpt table after truncating image
    ```
- xzip the image file and rename it in the format `ArPiRobot-[version]-[config].img.xz`
    ```sh
    xz -z image_name.img -v -T 0
    ```

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
