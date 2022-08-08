# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi Boards
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

*Note: This method is currently untested. There may be unforseen issues with this method.*

- It should be possible to use a `systemd-nspawn` container along with `qemu-user-static` to build the image without actual hardware.
- Expand base image, attach as loopback device, grow root partition, mount it, setup a `systemd-nspawn` container, boot the container, run image scripts (rebooting container as needed), then once done shutdown container and shrink root partition then image.


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
