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
# script:      dt-update_program.sh
# description: Replace the current robot program with the project in  the specified folder
# author:      Marcus Behel
# version:     v1.0.0
#####################################################################################

# Usage: dt-update_program.sh full/path/to/project/folder

if [ $# -ne 1 ]; then
    printf "Usage: $0 project_folder\n"
    exit 1
fi

PROJ_FOLDER="$1"

rm -rf ~/arpirobot/*
mkdir -p ~/arpirobot/
cp -r "$PROJ_FOLDER"/* ~/arpirobot/
chmod +x ~/arpirobot/*
dos2unix ~/arpirobot/main.sh
