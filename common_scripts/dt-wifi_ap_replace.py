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

# Country code not set via network manager
# Use iw reg set to apply it now
os.system("iw reg set {}".format(sys.argv[3]))

# Write config file to apply it on boot
if os.path.exists("/etc/sysconfig/regdomain"):
    with fileinput.FileInput("/etc/sysconfig/regdomain", inplace=True, backup='.bak') as file:
        for line in file:
            if line.startswith("COUNTRY="):
                continue
            else:
                print(line, end='')
        print("COUNTRY={}".format(sys.argv[3]))
else:
    os.makedirs("/etc/sysconfig", exist_ok=True)
    with open("/etc/sysconfig/regdomain", "w") as file:
        file.write("COUNTRY={}".format(sys.argv[3]))
    