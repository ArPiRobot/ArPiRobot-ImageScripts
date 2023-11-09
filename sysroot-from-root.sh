#!/usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root!"
    exit 1
fi

# Parse arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 root_dir dest_folder"
    echo "Makes a sysroot folder from a root folder (mounted image, debootstrap, etc)."
    echo ""
    echo "Example:"
    echo "  $0 /mnt/jetsonroot $HOME/sysroot-jetson"
    echo ""
    exit 1
fi

# Make sure image file exists
rootdir="$1"
if [ ! -d "$rootdir" ]; then
    echo "Root directory does not exist."
    exit 1
fi

# Get absolute path with no trailing slash
# Important for how links are fixed
destdir="$(realpath "$2")"
destdir="${destdir%"/"}"
if [ ! -d "$destdir" ]; then
    echo "Destination folder does not exist."
    exit 1
fi

# Copy files matching certain patterns
echo "Copying files to sysroot directory"
rsync -a \
    --exclude=bin \
    --exclude=sbin \
    --exclude=src \
    --exclude=share \
    --exclude=libexec \
    --exclude=games \
    --exclude=lib/aarch64-linux-gnu/dri \
    --exclude=lib/firmware \
    --exclude=local/cuda-10.2/doc \
    --exclude=local/cuda-10.2/samples \
    --exclude=lib/systemd \
    "$rootdir/usr/" "$destdir/usr/"
rsync -a "$rootdir/opt/" "$destdir/opt/"
rsync -a "$rootdir/lib/" "$destdir/lib/"
echo ""

# Convert links to all be relative (absolute links won't work in porable sysroot)
echo "Fixing links in sysroot"
while read l; do
    if [ -z "$l" ]; then
        # Empty string -> find probably found nothing?
        continue
    fi

    # Directory containing the link
    ldir=$(dirname "$l")

    # Absolute target of link
    tabs=$(readlink "$l")

    # Absolute target in sysroot directory
    tabsnew="$destdir/$tabs"

    # Relative target in sysroot directory
    trelnew="$(realpath -m --relative-to="$ldir" "$tabsnew")"

    # Replace link with relative link
    ln -sf "$trelnew" "$l"
done <<< "$(find "$destdir" -type l -lname '/*')"
echo ""

# Finally, check for any broken links
# This is mostly useful in determining if anything important was missed previously
# This doesn't fix broken links. Just prints them so user knows if script
# needs to be modified to fix them
echo "Checking for broken links"
while read l; do
    if [ ! -L "$l" ] || [ ! -e "$l" ]; then
        t=$(readlink "$l")
        echo "Found broken link in sysroot: $l -> $t"
    fi
done <<< "$(find "$destdir" -type l)"
echo ""

# Done. No cleanup necessary.
echo "Sysroot created."
