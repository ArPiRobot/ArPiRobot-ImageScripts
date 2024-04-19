#!/usr/bin/env bash

# Note: Need full path to iw b/c DeployTool doesn't run a shell, thus sbin not in path
COUNTRY_LINE=$(/usr/sbin/iw reg get | grep country | head -1)
COUNTRY=$(echo "$COUNTRY_LINE" | sed -z 's/country //g')
COUNTRY="${COUNTRY%:*}"

if [ $# -eq 0 ]; then
    echo "$COUNTRY"
    exit 0
else
    if [ $# -ne 1 ]; then
        echo "Either call with zero or one arguments!"
        echo "$0 [NEW_COUNTRY_CODE]"
        exit 1
    fi
fi

# Apply now
sudo /usr/sbin/iw reg set "$1"

# Configure to be applied on boot
echo "options cfg80211 ieee80211_regdom=$1" | sudo tee /etc/modprobe.d/cfg80211_regdomain.conf > /dev/null
