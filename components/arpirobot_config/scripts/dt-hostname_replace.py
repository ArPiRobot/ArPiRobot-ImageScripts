#!/usr/bin/python3

import sys
import fileinput

# four args plus name of script
# dt-hostname_replace.py NEW_HOSTNAME
if len(sys.argv) != 2:
    print("Must be exactly one argument!")
    sys.exit(1)

with open("/etc/hostname") as f:
    old_hostname = f.readline().replace("\r", "").replace("\n", "")

with fileinput.FileInput("/etc/hosts", inplace=True, backup='.bak') as file:
    for line in file:
        line = line.replace(old_hostname, sys.argv[1])
        print(line, end='')

with open("/etc/hostname", "w") as f:
    f.write(sys.argv[1] + "\n")

with fileinput.FileInput("/etc/dnsmasq.conf", inplace=True, backup='.bak') as file:
    for line in file:
        if line.startswith("address="):
            first_slash = line.find("/")
            second_slash = line.find("/", first_slash + 1)
            if first_slash != -1 and second_slash != -1:
                line = line[0:first_slash+1] + sys.argv[1] + ".local" + line[second_slash:]
            print(line)
        else:
            print(line, end='')