# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi Boards
    - RasPiOS Lite Buster (10) 32-bit (`scripts_rpibuster`)
    <!--Ubuntu Server Bionic (18.04) 64-bit (`scripts_rpibionic`)-->


## Using Scripts

- Easiest option is to flash an SD card with the OS image and boot it on the actual hardware. Then clone this repo and run the correct scripts. Then shrink the partition and read the sd card contents to an image file. Delete the image creation log & state files (in `/root`) before making the image.

- If the actual hardware is not available, `qmeu-user-static` binaries and `chroot`. Flash an sd card with the base image and connect it to a Linx system / VM. While using the raw image is hypothetically possible (instead of flashing) it would need to be grown and re-shrunk when done. If using this method, there should be no need to reconfigure the image to expand the root partition on next boot. Delete the image creation log & state files (in `/root`) before making the image.

```
# Install required tools
sudo apt install qemu-user-static

# Mount filesystems
sudo mkdir /mnt/sdroot
sudo mount /dev/mmcblk0p2 /mnt/sdroot
sudo mount /dev/mmcblk0p1 /mnt/sdroot/boot

# Will use qmeu-arm-static or qmeu-aarch64-static
sudo chroot /mnt/sdroot /bin/bash

# Then copy or clone this repository and run the scripts in the chroot (skip configexpand)
```


## License

```
ArPiRobot-ImageScripts is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ArPiRobot-ImageScripts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with ArPiRobot-ImageScripts.  If not, see <https://www.gnu.org/licenses/>.
```
