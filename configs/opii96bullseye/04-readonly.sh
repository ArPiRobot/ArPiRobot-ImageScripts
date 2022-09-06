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


# NOTE: System boots rw and switches to ro after boot
# This allows services that need rw access (at least for first boot) to still work
# even though image is created in chroot and never boots rw before booting in use

# Remove log & swap software
apt-get -y purge logrotate dphys-swapfile rsyslog

# Edit systemd-random-seed.service
cat > /lib/systemd/system/systemd-random-seed.service << 'EOF'
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

# Remove default /tmp mount line in /etc/fstab
sed -i 's/tmpfs \/tmp  tmpfs nodev,nosuid,mode=1777  0 0//g' /etc/fstab

# Add tmpfs entries to fstab
cat >> /etc/fstab << 'EOF'
tmpfs           /tmp             tmpfs   nosuid,nodev,nofail         0       0
tmpfs           /var/log         tmpfs   nosuid,nodev,nofail         0       0
tmpfs           /var/tmp         tmpfs   nosuid,nodev,nofail         0       0
tmpfs           /var/lib/misc    tmpfs   nosuid,nodev,nofail         0       0
EOF

# Additions to bashrc
cat >> /etc/bash.bashrc << 'EOF'
set_bash_prompt(){
    fs_mode=$(mount | sed -n -e 's/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p')
    PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}
alias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /media/boot'
alias rw='sudo mount -o remount,rw / ; sudo mount -o remount,ro /media/boot'
PROMPT_COMMAND=set_bash_prompt
EOF

# Additions to bash_logout
cat >> /etc/bash.bash_logout << 'EOF'
sudo mount -o remount,rw /
sudo mount -o remount,rw /media/boot
history -a
sudo fake-hwclock save
sudo mount -o remount,ro /
sudo mount -o remount,ro /media/boot
EOF

# Auto reboot on kernel panic
echo "kernel.panic = 10" > /etc/sysctl.d/01-panic.conf

# Disable daily apt services
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.timer
# systemctl disable unattended-upgrades.service

# Disable systemd-rfkill
systemctl disable systemd-rfkill
systemctl mask systemd-rfkill

# Write script to make ro after boot (relies on custom systemd service from sysconfig script)
cat > /usr/local/last_boot_scripts/50-ro-post-boot.sh << 'EOF'
#!/usr/bin/env bash
mount -o ro,remount /
sudo mount -o remount,ro /media/boot
EOF
chmod +x /usr/local/last_boot_scripts/50-ro-post-boot.sh
