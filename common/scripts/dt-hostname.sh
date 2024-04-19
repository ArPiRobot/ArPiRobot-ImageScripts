#!/bin/bash
#####################################################################################
#
# Copyright 2020 Marcus Behel
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
# along with ArPiRobot-ImageScripts.  If not, see <https://www.gnu.org/licenses/>.
#####################################################################################
# script:      dt-hostname.sh
# description: Prints or sets the hostname of the system. If setting the hostname
#              the python script by the same name is used.
# author:      Marcus Behel
# version:     v1.0.0
#####################################################################################


# If no arguments print the current hostname
if [ $# -eq 0 ]; then
    cat /etc/hostname
    exit 0
else
    if [ $# -ne 1 ]; then
        echo "Either call with zero or one arguments!"
        echo "$0 [NEW_HOSTNAME]"
        exit 1
    fi
fi

sudo dt-hostname_replace.py "$1"
