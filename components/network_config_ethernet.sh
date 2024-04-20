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


# Note: Can't use nmcli in chroot, thus write a config file instead
cat > "/etc/NetworkManager/system-connections/Wired Connection 1.nmconnection" << 'EOF'
[connection]
id=Wired connection 1
uuid=33ef1f97-4338-3da0-b2b3-ba908037697d
type=ethernet
autoconnect-priority=-999
interface-name=eth0

[ethernet]

[ipv4]
address1=192.168.11.1/24
method=shared

[ipv6]
addr-gen-mode=default
method=disabled

[proxy]

EOF
chmod 600 "/etc/NetworkManager/system-connections/Wired Connection 1.nmconnection"