#!/usr/bin/env python3

from distutils.command.config import config
import logging
import shutil
import sys
import os
import argparse
import platform


def main():
    script_dir = os.path.realpath(os.path.dirname(__file__))

    # CLI arguments
    parser = argparse.ArgumentParser(description="Creates a custom ArPirobot OS image based on a base OS image for the target board using one of several configurations.")
    parser.add_argument("config", type=str, help="Name of the config to use to generate the image.")
    parser.add_argument("version", type=str, help="Version string of the image (exclude config).")
    res = parser.parse_args()
    
    # Config check
    config_dir = os.path.join(script_dir, "configs", res.config)
    if not os.path.exists(config_dir):
        logging.error("The specified config '{}' is not valid.".format(res.config))
        exit(1)

    # TODO: Write image version txt file
    # TODO: Run each sh script for the config
    


if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler("make_image.log", mode='w'),
            logging.StreamHandler(sys.stdout)
        ],
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    try:
        main()
    except:
        logging.error("Script terminated due to keyboard interrupt.")
    
