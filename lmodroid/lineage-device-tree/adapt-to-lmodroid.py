#!/usr/bin/env python3

import argparse
import glob
import json
import os
import shutil

parser = argparse.ArgumentParser()
parser.add_argument(
    "tree", help="Lineage device tree.")
args = parser.parse_args()


def mergeDirs(scr_path, dir_path):
    files = next(os.walk(scr_path))[2]
    folders = next(os.walk(scr_path))[1]
    for file in files:  # Copy the files
        scr_file = scr_path + "/" + file
        dir_file = dir_path + "/" + file
        if os.path.exists(dir_file):
            dir_file = os.path.splitext(dir_file)[0] + "_lineage" + os.path.splitext(dir_file)[1]
        shutil.copy(scr_file, dir_file)
    for folder in folders:  # Merge again with the subdirectories
        scr_folder = scr_path + "/" + folder
        dir_folder = dir_path + "/" + folder
        # Create the subdirectories if dont already exist
        if not os.path.exists(dir_folder):
            os.mkdir(dir_folder)
        mergeDirs(scr_folder, dir_folder)

def globalFindReplace(directory, find, replace, filePattern):
    for filepath in glob.iglob(directory + '/**/' + filePattern, recursive=True):
        with open(filepath) as file:
            s = file.read()
        s = s.replace(find, replace)
        with open(filepath, "w") as file:
            file.write(s)

# Adapt Lineage overlays
for (dirpath, dirnames, filenames) in os.walk(args.tree):
    if 'lineage-sdk' in dirnames:
        # Remove LineageSettingsProvider
        if os.path.exists(dirpath + '/lineage-sdk/packages/LineageSettingsProvider'):
            shutil.rmtree(
                dirpath + '/lineage-sdk/packages/LineageSettingsProvider', ignore_errors=True)

        # Replace lineage-sdk to frameworks/base
        if os.path.exists(dirpath + '/lineage-sdk/lineage'):
            shutil.move(dirpath + '/lineage-sdk/lineage',
                        dirpath + '/lineage-sdk/core')

        if not os.path.exists(dirpath + '/frameworks/base'):
            shutil.move(dirpath + '/lineage-sdk', dirpath + '/frameworks/base')
        else:
            mergeDirs(dirpath + '/lineage-sdk', dirpath + '/frameworks/base')
            shutil.rmtree(dirpath + '/lineage-sdk', ignore_errors=True)
            
        # Replace overlay-lineage to overlay-lmodroid
        if 'lineage' in os.path.basename(dirpath):
            new_basename = os.path.basename(
                dirpath).replace('lineage', 'lmodroid')
            shutil.move(dirpath, os.path.dirname(dirpath) + '/' + new_basename)
            globalFindReplace(args.tree, os.path.basename(
                dirpath), os.path.basename(dirpath).replace('lineage', 'lmodroid'), "*.mk")

        # Done
        break


# Replace lineage_<codename> to lmodroid_<codename>
device_mk = glob.glob(args.tree + "/lineage_*.mk")
if len(device_mk) > 0:
    new_device_mk = os.path.basename(device_mk[0]).replace("lineage_", "lmodroid_")
    new_device_mk_path = os.path.dirname(device_mk[0]) + "/" + new_device_mk
    os.rename(device_mk[0], new_device_mk_path)

globalFindReplace(args.tree, "lineage_", "lmodroid_", "*.mk")

# Replace lineage vendor inherits to lmodroid
globalFindReplace(args.tree, "vendor/lineage", "vendor/lmodroid", "*.mk")

# Fix Doze resources lib
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.mk")
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.bp")

# Replace lineage dependencies to lmodroid
if os.path.exists(args.tree + '/lineage.dependencies'):
    shutil.move(args.tree + '/lineage.dependencies', args.tree + '/lmodroid.dependencies')
    new_deps_path = args.tree + '/lmodroid.dependencies'
    
    with open(new_deps_path) as f:
        deps = json.load(f)

    for dep in deps:
        if dep['repository'].startswith('android_device_') and "sepolicy" not in dep['repository']:
            dep['repository'] = dep['repository'].replace(
                'android_device_', 'LMODroid-Devices/device_')
        else:
            dep['remote'] = "lineage"
                
    with open(new_deps_path, 'w') as outfile:
        json.dump(deps, outfile, indent=2, sort_keys=True)
