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

def globalFindReplace(directory, find, replace, filePattern, exceptions=[]):
    for filepath in glob.iglob(directory + '/**/' + filePattern, recursive=True):
        with open(filepath) as file:
            s = file.read()
        completed_lines = []
        has_change = False
        for line in s.splitlines(True):
            exception = None
            for ex in exceptions:
                if ex in line:
                    exception = ex
                    break
            if exception is None or exception not in line:
                if find in line:
                    has_change = True
                completed_lines.append(line.replace(find, replace))
            else:
                completed_lines.append(line)

        if has_change:
            with open(filepath, "w") as file:
                file.writelines(completed_lines)

def globalRemoveDuplicateLines(directory, find, filePattern):
    for filepath in glob.iglob(directory + '/**/' + filePattern, recursive=True):
        with open(filepath) as file:
            s = file.read()
        completed_lines = s.splitlines(True)
        index = 0
        found = False
        for line in s.splitlines(True):
            if find in line:
                if found:
                    completed_lines.pop(index)
                    index -= 1
                found = True
            index += 1
        if found:
            with open(filepath, "w") as file:
                file.writelines(completed_lines)

# Adapt Lineage overlays
for (dirpath, dirnames, filenames) in os.walk(args.tree):
    if 'lineage-sdk' in dirnames:
        # Remove LineageSettingsProvider
        if os.path.exists(dirpath + '/lineage-sdk/packages/LineageSettingsProvider'):
            shutil.move(dirpath + '/lineage-sdk/packages/LineageSettingsProvider',
                        dirpath + '/lineage-sdk/packages/SettingsProvider')

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
            if os.path.exists(os.path.dirname(dirpath) + '/' + new_basename):
                shutil.rmtree(os.path.dirname(dirpath) + '/' +
                              new_basename, ignore_errors=True)
            shutil.move(dirpath, os.path.dirname(dirpath) + '/' + new_basename)
            globalFindReplace(args.tree, os.path.basename(
                dirpath), os.path.basename(dirpath).replace('lineage', 'lmodroid'), "*.mk")

        # Done
        break


# Replace lineage_<codename> to lmodroid_<codename>
device_mks = glob.glob(args.tree + "/**/lineage_*.mk", recursive=True)
for device_mk in device_mks:
    new_device_mk = os.path.basename(device_mk).replace("lineage_", "lmodroid_")
    new_device_mk_path = os.path.dirname(device_mk) + "/" + new_device_mk
    os.rename(device_mk, new_device_mk_path)

globalFindReplace(args.tree, "lineage_", "lmodroid_", "*.mk", ["defconfig", "manifest"])

# Replace lineage vendor inherits to lmodroid
globalFindReplace(args.tree, "vendor/lineage", "vendor/lmodroid", "*.mk", ["defconfig"])

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

# Fix lineageos.internal dependency
globalFindReplace(args.tree, "org.lineageos.platform.internal",
                  "VendorSupport-preference", "*.mk")
globalFindReplace(args.tree, "org.lineageos.platform.internal",
                  "VendorSupport-preference", "*.bp")
globalFindReplace(args.tree, "org.lineageos.internal.util",
                  "com.libremobileos.support.util", "*.java")
globalFindReplace(args.tree, "org.lineageos.platform.internal.R",
                  "com.android.internal.R", "*.java")
globalFindReplace(args.tree, "lineageos.providers.LineageSettings",
                  "android.provider.Settings", "*.java")
globalFindReplace(args.tree, "LineageSettings",
                  "Settings", "*.java")
globalRemoveDuplicateLines(args.tree, "android.provider.Settings;", "*.java")

# LineageOS intents
globalFindReplace(args.tree, "lineageos.content.Intent.ACTION_INITIALIZE_LINEAGE_HARDWARE",
                  '"lineageos.intent.action.INITIALIZE_LINEAGE_HARDWARE"', "*.java")
globalFindReplace(args.tree, "lineageos.content.Intent",
                  "Intent", "*.java")
