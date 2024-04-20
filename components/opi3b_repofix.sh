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

# This repo is not setup properly (missing GPG key) and just causes errors
rm /etc/apt/sources.list.d/docker.list

# Switch to standard debian repo instead of mirror
sed -i 's/repo.huaweicloud.com/deb.debian.org/g' /etc/apt/sources.list