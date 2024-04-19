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
# script:      dt-getmeminfo.sh
# description: Uses free and awk to print the used and total memory
# author:      Marcus Behel
# version:     v1.0.0
#####################################################################################

#Print used mem
free -k | awk '/used/ {for (i=1;i<=NF;i++) {if ($i=="used") col=i+1}} /^Mem:/ {print $col}'

# Print total mem
free -k | awk '/total/ {for (i=1;i<=NF;i++) {if ($i=="total") col=i+1}} /^Mem:/ {print $col}'
