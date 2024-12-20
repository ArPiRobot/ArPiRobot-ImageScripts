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
- Run `sudo ./make_image.py [config] [version]`
- Once done, this will result in an image file in `build/`. The image will be compressed using xz

## Creating Sysroots

- Requires Linux system with `qemu-user-static` package installed
- Run `sudo ./make_sysroots.sh [version]` eg `./make_sysroots.sh 1.1.0`
- All sysroots will be built in `build-sysroot` as `.tar.gz` packages

## Image Testing Checklist


### On Boot: 

- [ ] Root filesystem expands on first boot
- [ ] SSH host keys are regenerated at first boot (/etc/ssh/ssh_host*)
- [ ] Filesystem is remounted readonly after boot


### WiFi:

- [ ] WiFi adapter regulatory domain defaults to unset (sudo iw reg get)
- [ ] WiFi network is generated and can be connected to
- [ ] Can login to computer via SSH using 192.168.10.1

### Ethernet:

- [ ] DHCP assigns address when cable connected
- [ ] Can communicate with computer at 192.168.11.1

### Hardware:

- [ ] All I2C interfaces are available in OS (/dev/i2c-*)
- [ ] All SPI interfaces are available in OS (/dev/spidev*.*)
- [ ] All UART interfaces are available in OS (/dev/ttyS*, /dev/ttyAMA*, etc)
- [ ] All GPIO devices are available in OS (/dev/gpiochip*)
- [ ] Can execute the following without errors
    - [ ] v4l2-ctl --list-devices
    - [ ] cam -l

### Misc:

- [ ] Version file exists at /usr/local/arpirobot-image-version.txt
- [ ] i2c and spi default files exist at /usr/local
- [ ] Switching between rw and ro works

### ArPiRobot Setup:

- [ ] Robot program service starts on boot
- [ ] Mediamtx service starts on boot
- [ ] Deploy tool can connect, get robot status, deploy code, and read logs
- [ ] Deployed code runs using correct I/O provider for the device (pigpio or lgpio)
- [ ] Robot program is able to link to (and load) ALL I/O providers (pigpio, lgpio, libserialport). This is tested by building corelib with all providers enabled (linking against dynamic libs in sysroot) and verifying the library can be loaded at runtime with a deployed program.

### TestPlatform code:

- [ ] Connect board to test platform (see hardware setup description in robot.py)
- [ ] Set correct board in robot.py
- [ ] Deploy the test platform code on the test platform to ensure all features work as expected
- [ ] See comments in robot.py for details on expected outcomes from the program.

 