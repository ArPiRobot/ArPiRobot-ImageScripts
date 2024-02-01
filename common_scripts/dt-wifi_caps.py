#!/usr/bin/env python3

import subprocess
import re


def count_start(msg: str, prefix: str):
    count = 0
    for i in msg:
        if i == prefix:
            count += 1
        else:
            return count
    return count

# Note: Need full path to iw b/c sbin not in PATH when using ssh with no shell (DT does this)
res = subprocess.run(["/usr/sbin/iw", "phy"], stdout=subprocess.PIPE)
output = res.stdout.decode().replace("\t", "    ")

channels_24 = []
channels_24_disabled = []
channels_50 = []
channels_50_disabled = []

band_indent = -1
freq_indent = -1

for line in output.splitlines():
    if band_indent != -1:
        if count_start(line, " ") <= band_indent:
            # End of band section
            band_indent = -1
            if freq_indent != -1:
                # Also end of frequencies section
                freq_indent = -1
    if band_indent == -1:
        if line.strip().startswith("Band"):
            # Start of band section
            band_indent = count_start(line, " ")
    else:
        # In band section
        if freq_indent != -1:
            if count_start(line, " ") <= freq_indent:
                # End of frequencies section
                freq_indent = -1
        if freq_indent == -1:
            if line.strip().startswith("Frequencies"):
                # Start of frequencies section
                freq_indent = count_start(line, " ")
        else:
            # In frequencies section
            # Each line should be a frequency line
            # Ex: * 5170 MHz [34] (20.0 dBm)
            sline = line.strip()
            if re.match("^\* [0-9]+ MHz \[[0-9]+\] \(([0-9]+\.?[0-9]* dBm|disabled)\) ?\(?.*\)?$", sline):
                open_idx = sline.find("[")
                close_idx = sline.find("]")
                if sline[2] == "2":
                    channels_24.append(sline[open_idx+1:close_idx])
                    if sline.find("disabled") != -1:
                        channels_24_disabled.append(sline[open_idx+1:close_idx])
                elif sline[2] == "5":
                    channels_50.append(sline[open_idx+1:close_idx])
                    if sline.find("disabled") != -1:
                        channels_50_disabled.append(sline[open_idx+1:close_idx])


print("2.4GHz: {}".format(channels_24))
print("2.4GHz Disabled: {}".format(channels_24_disabled))
print("5.0GHz: {}".format(channels_50))
print("5.0GHz Disabled: {}".format(channels_50_disabled))
