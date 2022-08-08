#!/usr/bin/env bash
################################################################################
#
# Copyright 2022 Marcus Behel
#
# This file is part of ArPiRobot-ImageScripts.
# 
# ArPiRobot-ImageScripts is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ArPiRobot-ImageScripts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with ArPiRobot-ImageScripts. If not, see <https://www.gnu.org/licenses/>
################################################################################
# script:      01_readonly.sh
# description: Make OS readonly
# author:      Marcus Behel
################################################################################

# Initialization
DIR=$(realpath $(dirname "$0"))         # get directory of this script
ORIG_CWD=$(pwd)                         # store original working directory
cd "$DIR"                               # cd to script directory
source "$DIR/../99_functions.sh"        # source helper functions file
check_root                              # ensure running as root

# Body of the script
{
    script=$(basename "$0")
    lastscript=$(read_last_stage)
    echo "Running \"${script}\":"
    echo "Last run script: \"${lastscript}\"."
    echo "--------------------------------------------------------------------------------"

    # Code goes here
    # Make system readonly
    # Based on process used by https://gitlab.com/larsfp/rpi-readonly/-/blob/master/setup.sh

    # apt upgrade ran in last script state. Make sure it finished.
    printf "Making sure dpkg configure finished after upgrade..."
    dpkg --configure -a
    print_status

    echo "Removing swapfile and log software..."
    apt-get purge -y logrotate dphys-swapfile rsyslog
    print_status

    echo "Changing boot cmdline"
    uuid=`grep '/ ' /etc/fstab | awk -F'[=]' '{print $2}' | awk '{print $1}'`
    print_if_fail
    echo "console=serial0,115200 console=tty1 root=PARTUUID=$uuid rootfstype=ext4 fsck.repair=yes rootwait noswap ro fastboot rfkill.default_state=1" > /boot/cmdline.txt
    print_status

    echo "Editing system services..."
    rm /var/lib/systemd/random-seed
    print_if_fail
    ln -s /tmp/random-seed /var/lib/systemd/random-seed
    print_if_fail
    cp /lib/systemd/system/systemd-random-seed.service /lib/systemd/system/systemd-random-seed.service.backup
    print_if_fail
    cat > /lib/systemd/system/systemd-random-seed.service << EOF
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Load/Save Random Seed
Documentation=man:systemd-random-seed.service(8) man:random(4)
DefaultDependencies=no
RequiresMountsFor=/var/lib/systemd/random-seed
Conflicts=shutdown.target
After=systemd-remount-fs.service
Before=sysinit.target shutdown.target
ConditionVirtualization=!container

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/echo '' >/tmp/random-seed
ExecStart=/lib/systemd/systemd-random-seed load
ExecStop=/lib/systemd/systemd-random-seed save
TimeoutSec=30s
EOF
    print_if_fail
    systemctl daemon-reload
    print_status

    echo "Editing fake-hwclock..."
    cp /etc/cron.hourly/fake-hwclock /etc/cron.hourly/fake-hwclock.backup
    print_if_fail
    cat > /etc/cron.hourly/fake-hwclock << EOF
#!/bin/sh
#
# Simple cron script - save the current clock periodically in case of
# a power failure or other crash
 
if (command -v fake-hwclock >/dev/null 2>&1) ; then
  ro=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p")
  if [ "$ro" = "ro" ]; then
    mount -o remount,rw /
  fi
  fake-hwclock save
  if [ "$ro" = "ro" ]; then
    mount -o remount,ro /
  fi
fi
EOF
    print_status

    echo "Editing fstab..."
    sed -i.bak "/boot/ s/defaults/defaults,ro/g" /etc/fstab
    print_if_fail
    sed -i "/ext4/ s/defaults/defaults,ro/g" /etc/fstab
    print_if_fail
    echo "
tmpfs           /tmp             tmpfs   nosuid,nodev         0       0
tmpfs           /var/log         tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp         tmpfs   nosuid,nodev         0       0
tmpfs           /var/lib/dhcpcd  tmpfs   nosuid,nodev         0       0
" >> /etc/fstab
    print_status

    echo "Configuring for auto reboot on kernel panic..."
    echo "kernel.panic = 10" > /etc/sysctl.d/01-panic.conf
    print_status

    echo "Disabling daily apt services..."
    systemctl disable apt-daily.service
    print_if_fail
    systemctl disable apt-daily.timer
    print_if_fail
    systemctl disable apt-daily-upgrade.service
    print_if_fail
    systemctl disable apt-daily-upgrade.timer
    print_status

    echo "Fixing dnsmasq on readonly filesystem..."
    echo "tmpfs /var/lib/misc tmpfs nosuid,nodev 0 0" | tee -a /etc/fstab
    print_status

    echo "Disabling systemd-rfkill service as it does not work on readonly filesystem..."
    systemctl disable systemd-rfkill.service
    print_if_fail
    systemctl mask systemd-rfkill.service
    print_if_fail
    systemctl disable systemd-rfkill.socket
    print_if_fail
    systemctl mask systemd-rfkill.socket
    print_status

    echo "Patching bashrc..."
    cat "$DIR/bashrc_additions" >> /etc/bash.bashrc
    print_status

    echo "Patching bash_logout..."
    cat "$DIR/bashlogout_additions" >> /etc/bash.bash_logout
    print_status

    echo "Disabling ntp service..."
    systemctl disable systemd-timesyncd.service
    print_status

    echo "Reboot required. Press enter to reboot."
    read n
    shutdown -r 5

    echo "--------------------------------------------------------------------------------"
    echo ""
} 2>&1 | tee -a "$AIS_LOGFILE"


# Cleanup
cd "$ORIG_CWD"                          # restore original working directory
write_last_stage                        # write this script's name to state file