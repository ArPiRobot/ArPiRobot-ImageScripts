#!/usr/bin/env python3

import logging
import shutil
import subprocess
import getpass
import sys
import os
import argparse
import glob
import urllib.request


def run_command(cmd_args):
    script_name = os.path.basename(cmd_args[0])
    proc = subprocess.Popen(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    with proc.stdout:
        for line in iter(proc.stdout.readline, b''):
            strline = line.decode("utf8")
            if strline.endswith("\n"):
                strline = strline[:-1]
            if strline.endswith("\r"):
                strline = strline[:-1]
            logging.info("({}) {}".format(script_name, strline))
    return proc.wait()


def main():
    script_dir = os.path.realpath(os.path.dirname(__file__))

    parser = argparse.ArgumentParser(description="Run in a chroot to modify a base image into an ArPiRobot image.")
    parser.add_argument("config", type=str, help="Name of the config to use to generate the image.")
    parser.add_argument("version", type=str, help="Version string of the image (exclude config).")
    parser.add_argument("-f", dest="force", action='store_true', help="(DANGEROUS) Force run the script even if a chroot is not detected.")
    args = parser.parse_args()
    
    logging.info("Ensuring config exists")
    config_dir = os.path.join(script_dir, "configs", args.config)
    if not os.path.exists(config_dir):
        logging.error("The specified config '{}' is not valid.".format(args.config))
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

    res = subprocess.run(["systemd-detect-virt", "-r"])
    if res.returncode != 0:
        if not args.force:
            logging.error("Not in a chroot. Refusing to run. Use -f to override.")
            exit(1)
        logging.warning("Continuing even though not in a chroot (-f specified).")

    logging.info("Writing image version file")
    with open("/usr/local/arpirobot-image-version.txt", "w") as f:
        f.write("{}-{}".format(args.version, args.config))

    # Search for all scripts in the config directory
    logging.info("Searching config directory for scripts")
    scripts = glob.glob("{}/*.sh".format(config_dir))
    scripts.sort()
    logging.info("Found {} scripts in config directory.".format(len(scripts)))
    for script in scripts:
        logging.debug(os.path.basename(script))

    # Run each script in alphabetic order
    for script in scripts:
        logging.info("Running script '{}'".format(os.path.basename(script)))
        ec = run_command([script])
        if ec != 0:
            logging.error("Failed to run script '{}'.".format(os.path.basename(script)))
            exit(1)

    logging.info("Done")
    logging.info("Exit the chroot, copy out the log file, and delete the ArPiRobot-ImageScripts directory.")
    

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
    
