# ArPiRobot-ImageScripts

Scripts to setup OS images for use with ArPiRobot framework.

Also includes scripts to generate development sysroots.

## Folder Structure

- `components`: Collection of bash scripts that actually set things up. See `components/_readme.txt` for organization details.
- `configs`: Contains yaml configuration files to define which components should run for a given board and what OS image for that board to base the ArPiRobot image on.
- `sysroot`: Scripts used to setup sysroots
- `make_image.py`: Used to create an OS image using one of the defined configs
- `make_sysroots.sh` Used to create development sysroots


## Creating Images

- Requires Linux system with `qemu-user-static` package installed
- Run `sudo ./make_image.py stage1 [config] [version]`
- Once done, this will result in an image file in `build/`. The image will be compressed using xz

## Creating Sysroots

- Requires Linux system with `qemu-user-static` package installed
- Run `sudo ./make_sysroots.sh [version]` eg `./make_sysroots.sh 1.1.0`
- All sysroots will be built in `build-sysroot` as `.tar.gz` packages

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
