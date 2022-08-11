#!/usr/bin/env python3

import logging
import shutil
import getpass
import sys
import os
import argparse
import glob
import urllib.request


def main():
    script_dir = os.path.realpath(os.path.dirname(__file__))

    parser = argparse.ArgumentParser(description="Run in a chroot to modify a base image into an ArPiRobot image.")
    parser.add_argument("config", type=str, help="Name of the config to use to generate the image.")
    parser.add_argument("version", type=str, help="Version string of the image (exclude config).")
    res = parser.parse_args()
    
    logging.info("Ensuring config exists")
    config_dir = os.path.join(script_dir, "configs", res.config)
    if not os.path.exists(config_dir):
        logging.error("The specified config '{}' is not valid.".format(res.config))
        exit(1)

    logging.info("Performing root check")
    if getpass.getuser() != "root":
        logging.error("This script must be run as root.")
        exit(1)

    logging.info("Checking for internet access")
    try:
        urllib.request.urlopen("https://google.com/")
    except:
        logging.exception("Internet access is required to run this script.")
        exit(1)

    # TODO: Check if in chroot. Warn & exit if not. Add cli flag to override
    # systemd-detect-virt -r

    # logging.info("Writing image version file")
    # with open("/usr/local/arpirobot-image-version.txt", "w") as f:
    #     f.write(res.version)

    # Run each script in the selected config directory
    logging.info("Searching config directory for scripts")
    scripts = glob.glob("{}/*.sh".format(config_dir))
    scripts.sort()
    logging.info("Found {} scripts in config directory.".format(len(scripts)))
    for script in scripts:
        logging.debug(os.path.basename(script))

    logging.info("Done")
    

if __name__ == "__main__":
    shandler = logging.StreamHandler(sys.stdout)
    fhandler = logging.FileHandler("make_image.log", mode='w')
    shandler.setLevel(logging.INFO)
    fhandler.setLevel(logging.DEBUG)
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[shandler, fhandler],
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    try:
        main()
        exit(0)
    except KeyboardInterrupt:
        logging.error("Script terminated due to keyboard interrupt.")
        exit(1)
    except Exception:
        logging.exception("Exception occurred running script.")
        exit(1)
    
