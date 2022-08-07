# ArPiRobot-ImageScripts

Scripts to setup an ArPiRobot OS image.

## Supported Boards and OS Images

- Raspberry Pi Boards
    - RasPiOS Lite Buster (10) 32-bit (`scripts_rpibuster`)
    <!--Ubuntu Server Bionic (18.04) 64-bit (`scripts_rpibionic`)-->


## Using Scripts

- Easiest option is to flash an SD card with the OS image and boot it on the actual hardware. Then clone this repo and run the correct scripts. Then shrink the partition and read the sd card contents to an image file. Delete the image creation log & state files (in `/root`) before making the image.


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
