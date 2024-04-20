#!/usr/bin/env python3

# Note: All of these should be builtin standard libraries
#       as they will be imported in stage2, which runs in chroot
#       which won't have other packages installed when it is run
import logging
import subprocess
import getpass
import sys
import os
import time
import shutil
import argparse
import urllib.request
from typing import List


def run_command(cmd_args, shell=False, custom_label=None):
    script_name = os.path.basename(cmd_args[0])
    if custom_label is not None:
        script_name = custom_label
    proc = subprocess.Popen(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=shell)
    stdout_buf = bytearray()
    with proc.stdout:
        for line in iter(proc.stdout.readline, b''):
            stdout_buf.extend(line)
            strline = line.decode("utf8")
            if strline.endswith("\n"):
                strline = strline[:-1]
            if strline.endswith("\r"):
                strline = strline[:-1]
            logging.info("({}) {}".format(script_name, strline))
    ec = proc.wait()
    return ec, stdout_buf

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
    # Setup logging
    shandler = logging.StreamHandler(sys.stdout)
    shandler.setLevel(logging.DEBUG)
    logging.basicConfig(
        level=logging.DEBUG,
        format="[%(levelname)s] %(message)s",
        handlers=[shandler]
    )

    script_dir = os.path.realpath(os.path.dirname(__file__))

    # Handle command line args
    parser = argparse.ArgumentParser()
    parser.add_argument("components", type=str, nargs="*", help="List of components to execute")
    args = parser.parse_args(sys.argv[2:])

    # Ensure running in proper conditions
    root_check()
    internet_check()
    chroot_check()
    
    # Mark all component scripts executable (chmod)
    logging.info("Making all components executable")
    ec, out = run_command("chmod +x {}/*.sh".format(os.path.join(script_dir, "components")), shell=True)
    if ec != 0:
        logging.error("chmod failed")
        exit(1)

    # Execute each component in order
    for component in args.components:
        logging.info("Running component {}".format(component))
        ec, out = run_command(os.path.join(script_dir, "components", "{}.sh".format(component)), custom_label="{}.sh".format(component))
        if ec != 0:
            logging.error("Component {} failed to execute.".format(component))
            exit(1)

################################################################################



################################################################################
# Stage 1: Runs on host system
################################################################################

class ExitOneError(Exception):
    def __init__(self):
        super().__init__()

def stage1_cleanup(loopback: str, mounts: List[str], mount_prefix: str):
    # Sleep avoids issues with unmounting too quickly after mount (eg if mount failure triggers cleanup)
    time.sleep(1)
    mounts.reverse()
    for mount in mounts:
        # Remove slash prefix from dest so os.path.join works
        full_mount = os.path.join(mount_prefix, mount[1:])
        if mount == "/dev":
            run_command(["umount", "-R", full_mount])
        else:
            run_command(["umount", full_mount])
        time.sleep(0.5)
    if mount_prefix != "":
        try:
            shutil.rmtree(mount_prefix)
        except:
            pass
    if loopback is not None and loopback != "":
        run_command(["losetup", "-d", loopback])

def stage1():
    # Handle command line args
    parser = argparse.ArgumentParser()
    parser.add_argument("config", type=str, help="Name of the config to use to generate the image.")
    parser.add_argument("version", type=str, help="Version string of the image (exclude config).")
    args = parser.parse_args(sys.argv[2:])

    script_dir = os.path.realpath(os.path.dirname(__file__))
    logfile = os.path.join(script_dir, "build", "make_image_{}.log".format(args.config))
    if not os.path.exists(os.path.dirname(logfile)):
        os.mkdir(os.path.dirname(logfile))

    # Setup logging
    shandler = logging.StreamHandler(sys.stdout)
    fhandler = logging.FileHandler(logfile, mode='w')
    shandler.setLevel(logging.DEBUG)
    fhandler.setLevel(logging.DEBUG)
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[shandler, fhandler],
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    loopback = None
    current_mounts = []
    working_root = os.path.join(script_dir, "build", "rootfs")
    imgscript_dir = os.path.join(working_root, "root", "imagescripts")

    # Modules that are not builtin should not be imported for stage2
    import yaml

    try:

        # Ensure running in proper conditions
        root_check()
        
        # Parse config
        config = None
        with open(os.path.join(script_dir, "configs", "{}.yaml".format(args.config))) as f:
            config = yaml.load(f, yaml.FullLoader)
        base_img = config['base_img']
        base_img_can_download = config['base_img_can_download']
        base_img_name = config['base_img_name']
        base_img_sha256 = config['base_img_sha256']
        expand_mb = config['expand_mb']
        partitions = config['partitions']
        components = config['components']
        if len(partitions) == 0:
            logging.error("Partitions cannot have length 0")
            raise ExitOneError()
        if len(components) == 0:
            logging.error("Components cannot have length 0")
            raise ExitOneError()
        
        # Prompt for deletion of existing image
        working_img = os.path.join(script_dir, "build", "ArPiRobot-{}-{}.img".format(args.version, args.config))
        if os.path.exists("{}.xz".format(working_img)):
            logging.error("Final image file exists. Move or delete this file. Exiting.")
            raise ExitOneError()


        # Make sure all referenced components exist
        missing_components = False
        for component in components:
            component_file = os.path.join(script_dir, "components", "{}.sh".format(component))
            if not os.path.exists(component_file):
                logging.error("Component {} missing".format(component))
                missing_components = True
        if missing_components:
            raise ExitOneError()
        
        # Download image and verify hash
        download_dir = os.path.join(script_dir, "build", "downloads")
        if not os.path.exists(download_dir):
            os.makedirs(download_dir)
        dest_file = os.path.join(download_dir, base_img_name)
        if not os.path.exists(dest_file):
            if base_img_can_download:
                logging.info("Downloading base image file")
                ec, out = run_command(["wget", base_img, "-O", dest_file])
                if ec != 0:
                    logging.error("Failed to download base image file")
                    raise ExitOneError()
            else:
                logging.error("Base image cannot be downloaded automatically.")
                logging.info("Download the image from {}".format(base_img))
                logging.info("Place it in {}/build/download then re-launch the script".format(script_dir))
                raise ExitOneError()
        else:
            logging.info("Skipping base image download, as it already exists")
        ec, out = run_command(["sha256sum", dest_file])
        if ec != 0:
            logging.error("Calculating hash failed")
            raise ExitOneError()
        calc_hash = out.decode().split(" ")[0]
        if calc_hash != base_img_sha256:
            logging.error("Hash of downloaded image does not match expected.")
            os.remove(dest_file)
            raise ExitOneError()

        # Extract base image
        logging.info("Decompressing base image")
        img_path = None
        if base_img_name.endswith(".xz"):
            img_path = dest_file[:-3] # remove .xz suffix
            if os.path.exists(img_path):
                os.remove(img_path)
            ec, out = run_command(["xz", "-k", "-d", dest_file])
        elif base_img_name.endswith(".7z"):
            img_path = dest_file[:-3] # remove .7z suffix
            img_path += ".img" # Add .img suffix
            if os.path.exists(img_path):
                os.remove(img_path)
            ec, out = run_command(["7z", "e", "-o{}".format(os.path.dirname(img_path)), dest_file, os.path.basename(img_path)])
        else:
            logging.error("Unknown compression format.")
            raise ExitOneError()
        if ec != 0:
            logging.error("Decompression failed.")
            raise ExitOneError()
        if os.path.exists(working_img):
            os.remove(working_img)
        shutil.move(img_path, working_img)
        logging.info("Working image: {}".format(working_img))

        # Expand image file
        logging.info("Expanding image file")
        ec, out = run_command("dd if=/dev/zero bs=1MiB count={} >> {}".format(expand_mb, working_img), shell=True)
        if ec != 0:
            logging.error("Failed to expand image file.")
            raise ExitOneError()

        # Setup loopback device
        time.sleep(1)
        logging.info("Setting up loopback device")
        ec, out = run_command(["losetup", "-f", "-P", "--show", working_img])
        if ec != 0:
            logging.error("Failed to setup loopback device")
            raise ExitOneError()
        loopback = out.decode().splitlines()[0].strip()
        logging.info("Loopback device = {}".format(loopback))

        # Grow last partition (this is assumed to be root partition)
        logging.info("Growing root partition")
        largest_part = 0
        for part, _ in partitions.items():
            if part > largest_part:
                largest_part = part
        ec, out = run_command(["growpart", loopback, str(largest_part)])
        if ec != 0:
            logging.error("Failed to grow root partition")
            raise ExitOneError()
        ec, out = run_command(["e2fsck", "-f", "-y", "{}p{}".format(loopback, largest_part)])
        if ec != 0:
            logging.error("Failed to grow root partition")
            raise ExitOneError()
        ec, out = run_command(["resize2fs", "{}p{}".format(loopback, largest_part)])
        if ec != 0:
            logging.error("Failed to grow root partition")
            raise ExitOneError()

        # Mount image partitions
        logging.info("Mounting image partitions")
        if os.path.exists(working_root):
            shutil.rmtree(working_root)
        os.makedirs(working_root)
        for partnum, dest in partitions.items():
            # Remove slash prefix from dest so os.path.join works
            full_dest = os.path.join(working_root, dest[1:])
            ec, out = run_command(["mount", "{}p{}".format(loopback, partnum), full_dest])
            if ec != 0:
                logging.error("Failed to mount partition {}".format(partnum))
                raise ExitOneError()
            current_mounts.append(dest)


        # Mount standard chroot binds
        logging.info("Binding system mounts")
        ec, out = run_command(["mount", "--rbind", "/dev", os.path.join(working_root, "dev")])
        if ec != 0:
            logging.error("Failed to bind /dev")
            raise ExitOneError()
        ec, out = run_command(["mount", "--make-rslave", os.path.join(working_root, "dev")])
        if ec != 0:
            logging.error("Failed to bind /dev")
            raise ExitOneError()
        current_mounts.append("/dev")
        ec, out = run_command(["mount", "--bind", "/proc", os.path.join(working_root, "proc")])
        if ec != 0:
            logging.error("Failed to bind /proc")
            raise ExitOneError()
        current_mounts.append("/proc")
        ec, out = run_command(["mount", "--bind", "/sys", os.path.join(working_root, "sys")])
        if ec != 0:
            logging.error("Failed to bind /sys")
            raise ExitOneError()
        current_mounts.append("/sys")

        # Copy to chroot
        logging.info("Copying to chroot")
        os.mkdir(imgscript_dir)
        shutil.copytree(os.path.join(script_dir, "components"), os.path.join(imgscript_dir, "components"))
        shutil.copy(os.path.join(script_dir, "make_image.py"), os.path.join(imgscript_dir, "make_image.py"))

        # Write version file in chroot dir
        logging.info("Writing image version file")
        with open(os.path.join(working_root, "usr", "local", "arpirobot-image-version.txt"), "w") as f:
            f.write("{}-{}".format(args.version, args.config))

        logging.info("Running stage2 in chroot")
        chroot_cmd = ["chroot", working_root, "/usr/bin/env", "python3", "/root/imagescripts/make_image.py"]
        chroot_cmd.append("stage2")
        chroot_cmd.extend(components)
        ec, out = run_command(chroot_cmd)
        if ec != 0:
            logging.error("Failed to execute stage 2")
            raise ExitOneError()

        # Finished successfully. Unmount and clean everything up
        logging.info("Cleaning up.")
        stage1_cleanup(loopback, current_mounts, working_root)
        loopback = None
        current_mounts = []
        working_root = ""

        # Compress the generated image using xz
        logging.info("Compressing image")
        ec, out = run_command(["xz", "-T", "0", "-z", working_img])
        if ec != 0:
            logging.error("Failed to compress image")
            raise ExitOneError()
        
    except ExitOneError as e:
        logging.info("Cleaning up.")
        stage1_cleanup(loopback, current_mounts, working_root)
        exit(1)
    except BaseException as e:
        logging.info("Cleaning up.")
        stage1_cleanup(loopback, current_mounts, working_root)
        raise e


################################################################################



################################################################################
# Entry point
################################################################################

def main():
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
    
