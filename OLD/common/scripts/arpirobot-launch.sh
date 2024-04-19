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
# script:      arpirobot-launch.sh
# description: Runs the robot program in ~/arpirobot/
# author:      Marcus Behel
# version:     v1.0.0
#####################################################################################


MAIN_SCRIPT=~/arpirobot/main.sh
MAIN_TXT=~/arpirobot/main.txt

if [ -f "$MAIN_SCRIPT" ]; then
    "$MAIN_SCRIPT" > /tmp/arpirobot_program.log 2>&1
else
    # Fallback to old method if no main.sh script
    # main.txt would have a single line with the name of a python script to invoke
    file=$(head -n 1 $MAIN_TXT)
    PYTHONPATH=~/arpirobot python3 -u ~/arpirobot/$file > /tmp/arpirobot_program.log 2>&1
fi

exit 0
