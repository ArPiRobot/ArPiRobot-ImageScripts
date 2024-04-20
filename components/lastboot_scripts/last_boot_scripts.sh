#!/usr/bin/env bash
files=$(find /usr/local/last_boot_scripts/ -name "*.sh" | sort)
for file in $files; do
    echo "Running $file"
    bash "$file"
done