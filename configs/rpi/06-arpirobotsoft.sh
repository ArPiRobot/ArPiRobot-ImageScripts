#!/usr/bin/env bash

function exit_trap(){
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "\"${last_command}\" command failed with exit code $ec."
    fi
}
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap exit_trap EXIT



# Get architecture of an ELF binary
function binarch(){
    printf "$(readelf -h $1 | grep Machine: | sed -r 's/\s+Machine:\s+//g')"
}



# Install ArPiRobot-CameraStreaming
# Note: this installs services that run with multi-user target
# However, these services / programs are setup such that they do not
# need write access to filesystem, thus it shouldn't matter if lastcommands
# runs afterwards
orig_dir="$(pwd)"
cd /home/arpirobot
git clone https://github.com/ArPiRobot/ArPiRobot-CameraStreaming.git
chown -R arpirobot:arpirobot ArPiRobot-CameraStreaming
cd ArPiRobot-CameraStreaming
chmod +x ./install.sh
./install.sh arpirobot
arch=$(binarch $(which python3))
if [ "$arch" = "ARM" ]; then
    chmod +x ./install_rtsp_server_armv6.sh
    ./install_rtsp_server_armv6.sh arpirobot
elif [ "$arch" = "AArch64" ]; then
    chmod +x ./install_rtsp_server_aarch64.sh
    ./install_rtsp_server_aarch64.sh arpirobot
else
    echo "Unknown architecture. Cannot install rtsp-simple-server."
    exit 1
fi
sed -i 's/libcamera/raspicam/g' /home/arpirobot/camstream/default.txt
cd "$orig_dir"
rm -rf /home/arpirobot/ArPiRobot-CameraStreaming

# Scripts used by deploy tool
DIR="$(dirname "$0")"
cp "$DIR/../../common_scripts"/* /usr/local/bin/
cp "$DIR/scripts"/* /usr/local/bin/

# Service to start robot program
# Note: This uses the "custom" target and runs after the last boot commands
# This ensures that the filesystem will be readonly BEFORE the program starts
# This way, if the program changes to rw, it won't be changed back
# In other words, this prevents the following
# - arpirobot-program starts
# - user code starts
# - user code sets filesystem to rw
# - lastcommands.service starts
# - last boot scripts makes filesystem ro
# - user program expects rw filesystem, but it is actually ro
cat > /etc/systemd/system/arpirobot-program.service << 'EOF'
[Unit]
Description=Service to start the arpirobot program
After=lastcommands.service

[Service]
Type=simple
User=arpirobot
ExecStart=/usr/local/bin/arpirobot-launch.sh

[Install]
WantedBy=custom.target
EOF

# Create directory for robot program
mkdir -p /home/arpirobot/arpirobot
chown arpirobot:arpirobot /home/arpirobot/arpirobot
