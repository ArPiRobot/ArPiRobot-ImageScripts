#!/usr/bin/env bash
function exit_trap(){
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "\"${last_command}\" command failed with exit code $ec." >&2
    fi
}
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap exit_trap EXIT
DIR="$(dirname "$0")"

# Auto reboot on kernel panic
echo "kernel.panic = 10" > /etc/sysctl.d/01-panic.conf

# Set hostname
echo "ArPiRobot-Robot" | tee /etc/hostname
sed -i "s/raspberrypi/ArPiRobot-Robot/g" /etc/hosts

# Set locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

# Set keyboard layout
cat > /etc/default/keyboard << 'EOF'
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF

# Enable ssh server
systemctl enable ssh


# Script to regenerate ssh host keys on first boot.
# Requires last_commands service to be setup (from another component)

# Not actually needed. Both rpi and armbian images (orangepi images are armbian based)
# have a mechanism to do this out of the box. It is best to just use these as disabling
# them is not trivial without impacting other first boot behavior

# mkdir -p /usr/local/last_boot_scripts/
# cat > /usr/local/last_boot_scripts/10-ssh-host-keys.sh << 'EOF'
# #!/usr/bin/env bash
# rm -f /etc/ssh/ssh_host_*_key*
# ssh-keygen -A > /dev/null
# rm -f /usr/local/last_boot_scripts/10-ssh-host-keys.sh
# EOF
# chmod +x /usr/local/last_boot_scripts/10-ssh-host-keys.sh
