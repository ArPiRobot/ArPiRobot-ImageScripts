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
# script:      dt-getversions.sh
# description: Print in following order (each on new line) for deploy tool
#              Image version
#              Python interpreter version
#              Python library version
#              Raspbian tools version
#              Update version (if file exists, won't  for older updates)
# 
#              Output must match following example format
#              IMAGE_VERSION_NAME
#              PYTHON VERSION STRING from python3 --version
#              RASPBIAN TOOLS VERSION
#
#              Example:
#              Beta2
#              3.7.1
# author:      Marcus Behel
# version:     v1.0.0
#####################################################################################


# Print image version
VERSION=$(head -n 1 /usr/local/arpirobot-image-version.txt 2>/dev/null | sed -z '$ s/\n$//')
if [ -z "$VERSION" ]; then
    VERSION="UNKNOWN"
fi
printf "$VERSION\n"

# Print python version
python3 --version | sed -z 's/Python //g'


