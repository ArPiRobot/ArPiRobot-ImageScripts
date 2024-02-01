#!/usr/bin/python3

import sys
import fileinput
import os

# four args plus name of script
# dt-wifi_ap_replace.py SSID PASSWORD COUNTRY_CODE CHANNEL BAND
if len(sys.argv) != 6:
    print("Must be exactly five arguments!")
    sys.exit(1)

with fileinput.FileInput("/etc/NetworkManager/system-connections/RobotAP.nmconnection", inplace=True, backup='.bak') as file:
    for line in file:
        if line.startswith("ssid="):
            print("ssid=" + sys.argv[1])
        elif line.startswith("psk="):
            print("psk=" + sys.argv[2])
        elif line.startswith("band="):
            print("band=" + sys.argv[5])
        elif line.startswith("channel="):
            print("channel=" + sys.argv[4])
        else:
            print(line, end='')
    