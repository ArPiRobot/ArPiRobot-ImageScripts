#!/usr/bin/env python3

# Note: All of these should be builtin standard libraries
#       as they will be imported in stage2, which runs in chroot
#       which won't have other packages installed when it is run
import logging
import subprocess
import getpass
import sys
import os
import shutil
import argparse
import urllib.request


# def run_command(cmd_args):
#     script_name = os.path.basename(cmd_args[0])
#     proc = subprocess.Popen(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
#     with proc.stdout:
#         for line in iter(proc.stdout.readline, b''):
#             strline = line.decode("utf8")
#             if strline.endswith("\n"):
#                 strline = strline[:-1]
#             if strline.endswith("\r"):
#                 strline = strline[:-1]
#             logging.info("({}) {}".format(script_name, strline))
#     return proc.wait()

################################################################################
# System checks
################################################################################

def root_check():
    logging.info("Performing root check")
    if getpass.getuser() != "root":
        logging.error("This script must be run as root.")
        exit(1)


def internet_check():
    logging.info("Checking for internet access")
    try:
        urllib.request.urlopen("https://google.com/")
    except:
        logging.exception("Internet access is required to run this script.")
        exit(1)


def chroot_check():
    res = subprocess.run(["systemd-detect-virt", "-r"])
    if res.returncode != 0:
        logging.error("Not in a chroot. Refusing to run. Use -f to override.")
        exit(1)

################################################################################



################################################################################
# Stage 2: Runs in chroot
################################################################################

def stage2():
    # Handle command line args
    parser = argparse.ArgumentParser()
    parser.add_argument("components", type=str, nargs="*", help="List of components to execute")
    args = parser.parse_args(sys.argv[2:])

    # Ensure running in proper conditions
    root_check()
    internet_check()
    chroot_check()
    
    # TODO: Execute each component in order

################################################################################



################################################################################
# Stage 1: Runs on host system
################################################################################

def stage1():
    # Modules that are not builtin should not be imported for stage2
    import yaml

    # Handle command line args
    parser = argparse.ArgumentParser()
    parser.add_argument("config", type=str, help="Name of the config to use to generate the image.")
    parser.add_argument("version", type=str, help="Version string of the image (exclude config).")
    args = parser.parse_args(sys.argv[2:])

    # Ensure running in proper conditions
    root_check()
    
    # Parse config
    script_dir = os.path.realpath(os.path.dirname(__file__))
    config = None
    with open(os.path.join(script_dir, "configs", "{}.yaml".format(args.config))) as f:
        config = yaml.load(f, yaml.FullLoader)
    base_img = config['base_img']
    base_img_name = os.path.basename(base_img)
    base_img_sha256 = config['base_img_sha256']
    partitions = config['partitions']
    components = config['components']
    if len(partitions) == 0:
        logging.error("Partitions cannot have length 0")
        exit(1)
    if len(components) == 0:
        logging.error("Components cannot have length 0")
        exit(1)

    # Make sure all referenced components exist
    missing_components = False
    for component in components:
        component_file = os.path.join(script_dir, "components", "{}.sh".format(component))
        if not os.path.exists(component_file):
            logging.error("Component {} missing".format(component))
            missing_components = True
    if missing_components:
        exit(1)
    
    # Download image and verify hash
    download_dir = os.path.join(script_dir, "build", "downloads")
    if not os.path.exists(download_dir):
        os.makedirs(download_dir)
    dest_file = os.path.join(download_dir, base_img_name)
    if not os.path.exists(dest_file):
        logging.info("Downloading base image file")
        res = subprocess.run(["wget", base_img, "-O", dest_file], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if res.returncode != 0:
            logging.error("Failed to download base image file")
            exit(1)
    else:
        logging.info("Skipping base image download, as it already exists")
    res = subprocess.run(["sha256sum", dest_file], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if res.returncode != 0:
        logging.error("Calculating hash failed")
        exit(1)
    calc_hash = res.stdout.decode().split(" ")[0]
    if calc_hash != base_img_sha256:
        logging.error("Hash of downloaded image does not match expected.")
        os.remove(dest_file)
        exit(1)

    # Extract base image
    logging.info("Decompressing base image")
    img_path = None
    if base_img_name.endswith(".xz"):
        img_path = dest_file[:-3] # remove .xz suffix
        res = subprocess.run(["xz", "-k", "-d", dest_file], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    else:
        logging.error("Unknown compression format.")
        exit(1)
    if res.returncode != 0:
        logging.error("Decompression failed.")
        exit(1)
    working_img = os.path.join(script_dir, "build", "ArPiRobot-{}-{}.img".format(args.version, args.config))
    if os.path.exists(working_img):
        os.remove(working_img)
    shutil.move(img_path, working_img)
    logging.info("Working image: {}".format(working_img))

    # TODO: Extract and mount base image partitions
    # TODO: Mount standard chroot binds
    # TODO: Copy this script, configs, and components to chroot
    # TODO: Write version file in chroot dir

    logging.info("BEGIN STAGE 2")
    # TODO: Enter chroot and run stage 2 in chroot
    # TODO: Wait for stage 2 to complete and get exit code.
    logging.info("END STAGE 2")
    
    # TODO: Unmount standard binds
    # TODO: Unmount image (reverse order)
    # TODO: If stage 2 failed, exit now

    # Finished successfully
    logging.info("Done")
    exit(0)

################################################################################



################################################################################
# Entry point
################################################################################

def main():
    # Setup logging
    shandler = logging.StreamHandler(sys.stdout)
    shandler.setLevel(logging.DEBUG)
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[shandler],
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # TODO: Duplicate stdout and stderr to file

    # Launch
    if len(sys.argv) == 1:
        print("Usage: {} COMMAND".format(os.path.basename(sys.argv[0])))
        exit(1)
    if sys.argv[1] == "stage1":
        stage1()
    elif sys.argv[1] == "stage2":
        stage2()
    else:
        print("Unknown command.")
        exit(1)

    # logging.info("Writing image version file")
    # with open("/usr/local/arpirobot-image-version.txt", "w") as f:
    #     f.write("{}-{}".format(args.version, args.config))

################################################################################
    

if __name__ == "__main__":
    try:
        main()
        exit(0)
    except KeyboardInterrupt:
        logging.error("Script terminated due to keyboard interrupt.")
        exit(1)
    except Exception:
        logging.exception("Exception occurred running script.")
        exit(1)
    
