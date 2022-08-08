# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi Boards (Pi 4B, Pi Zero 2 W and older)
    - RasPiOS Lite Buster (10) 32-bit (`scripts_rpibuster`)
    <!--Ubuntu Server Bionic (18.04) 64-bit (`scripts_rpibionic`)-->


## Using Scripts to Make an Image

### Option 1: Using Actual Hardware

- Flash an SD card (or other medium as apropriate) with the correct base image
- Boot the SD card on the correct device
- Connect the device to the internet
- Clone this repo and run the correct set of scripts (in numeric order)
- Once all scripts have been run (across reboots as needed) remove the SD card and insert it into a Linux computer (desktop / laptop).
- Shrink the root partition using gparted
- Use dd to dump an image of the SD card to a file


### Option 2: Emulating Hardware (QEMU Virtual Machine)

- If it is possible to use qemu to emulate the target hardware, a virtual machine can be setup and use instead of a physical system.
- Follow the same steps as if using actual hardware, except the image will be booted directly (and probably needs to be grown before use and shrunk when done).

### Option 3: EXPERIMENTAL - Containers (with QEMU Userspace Emulator)

*Note: This method is not well tested!*

- It should be possible to use a `systemd-nspawn` container along with `qemu-user-static` to build the image without actual hardware.
- Expand base image, attach as loopback device, grow root partition, mount it, setup a `systemd-nspawn` container, boot the container, run image scripts (rebooting container as needed), then once done shutdown container and shrink root partition then image.

INSTRUCTIONS:

Run on host system

```sh
# Install required software (persumably x86_64 system)
sudo apt-get install -y qemu qemu-user-static binfmt-support cloud-guest-utils systemd-container

# Download and extract base image
wget image_link_here
unzip image_name.zip

# Increase img size (by 3G in this case)
sudo dd if=/dev/zero bs=1MiB count=3072 >> image_name.img

# Connect image to a loopback device
export imgloop=$(sudo losetup -f -P --show image_name.img)

# Grow root partition of the img (persumed to be partition 2)
sudo growpart $imgloop 2

# Resize filesystem to match partition (change partition number if necessary)
sudo e2fsck -f ${imgloop}p2
sudo resize2fs ${imgloop}p2

# Mount the image (make sure to mount other partitions correctly too). Change partition numbers as needed.
sudo mkdir /mnt/img-container
sudo mount ${imgloop}p2 /mnt/img-container
sudo mount ${imgloop}p1 /mnt/img-container/boot

# Create a systemd-nspawn container (and boot it)
sudo systemd-nspawn -D /mnt/img-container -b

################################################################################
# Clone and run the correct image scripts in the container now
################################################################################

# Only continue here once all scripts have been run

# Unmount partitions (change as needed)
sudo umount /mnt/img-container/boot
sudo umount /mnt/img-container

# Shrink root filesystem to minimum size (change part number if needed)
# sudo e2fsck -f ${imgloop}p2
# sudo resize2fs -M ${imgloop}p2
# TODO: Shrink actual partition?

# Then shrink using gparted
sudo gparted $imgloop

# Free loopback device
sudo losetup -d $imgloop

# Truncate extra space from end of image file
# Use fdisk to get sector size and end sector of last partition
sudo fdisk -l image_name.img

# Multiply sector size by last end sector plus 1 to get min size of file (in bytes)
sudo truncate --size=$[(last_end_sector+1)*sector_size] image_name.img

```

References:

- [https://wiki.debian.org/RaspberryPi/qemu-user-static](https://wiki.debian.org/RaspberryPi/qemu-user-static)

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
