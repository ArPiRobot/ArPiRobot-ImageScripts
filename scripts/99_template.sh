#!/usr/bin/env bash
#####################################################################################
#
# Copyright 2022 Marcus Behel
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
# script:      99_template.sh
# description: Template for implementing scripts
# author:      Marcus Behel
#####################################################################################


DIR=$(realpath $(dirname "$0"))

ORIG_CWD=$(pwd)
cd "$DIR"
{
    
    # Code goes here

} > "$AIS_LOGFILE" 2>&1
cd "$ORIG_CWD"