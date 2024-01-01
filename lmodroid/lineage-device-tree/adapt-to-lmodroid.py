#!/usr/bin/env python3

import argparse
import glob
import json
import os
import shutil
import subprocess

from config import *

parser = argparse.ArgumentParser()
parser.add_argument(
    "tree", help="Lineage device tree.")
parser.add_argument(
    "branch", help="Tree branch.", nargs='?')
args = parser.parse_args()

is_legacy_tree = False

if args.branch is None:
    print("No branch specified, using git current branch")
    process = subprocess.Popen(["git", "branch", "--show-current"], stdout=subprocess.PIPE)
    branch_name, branch_error = process.communicate()
    if branch_error:
        print("Error getting current branch name: " + branch_error)
        exit(1)
    args.branch = branch_name.decode("utf-8").strip()

LEGACY_BRANCHES = ["lineage-18", "lineage-19", "lineage-20", "eleven", "twelve", "thirteen"]

for legacy_branch in LEGACY_BRANCHES:
    if legacy_branch in args.branch:
        is_legacy_tree = True
        break

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

def globalFindReplace(directory, find, replace, filePattern, exceptions=[], append_lines=[]):
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
                completed_lines.append(line.replace(find, replace))
                if find in line:
                    has_change = True
                    completed_lines.extend(append_lines)
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

def globalReduceReservedSize(directory, reduce_size=184857600, find="RESERVED_SIZE", filePattern="*.mk", exceptions=["$("]):
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
                if find in line and ":=" in line:
                    has_change = True
                    try:
                        splitted_line = line.split(":=")
                        old_part_size = splitted_line[1].strip()
                        new_partition_size = int(old_part_size)
                        if new_partition_size > (reduce_size * 3):
                            new_partition_size -= reduce_size
                        completed_lines.append(
                            line.replace(old_part_size, str(new_partition_size)))
                    except:
                        completed_lines.append(line)
                        pass
                else:
                    completed_lines.append(line)
            else:
                completed_lines.append(line)

        if has_change:
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

globalFindReplace(args.tree, "lineage_", "lmodroid_", "*.mk",
                  ["defconfig", "manifest", "framework", ".config", "TARGET_KERNEL_CONFIG", "health"])

# Replace lineage vendor inherits to lmodroid
globalFindReplace(args.tree, "vendor/lineage", "vendor/lmodroid", "*.mk", ["defconfig", ".config", "TARGET_KERNEL_CONFIG"])

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
        if dep['repository'] in FORKED_REPOS:
            dep['repository'] = FORKED_REPOS[dep['repository']]
        elif dep['repository'].startswith('android_device_') and "sepolicy" not in dep['repository']:
            dep['repository'] = dep['repository'].replace(
                'android_device_', 'LMODroid-Devices/device_')
        else:
            dep['remote'] = "lineage"
                
    with open(new_deps_path, 'w') as outfile:
        json.dump(deps, outfile, indent=2, sort_keys=True)

# Fix lineageos.internal dependency
globalFindReplace(args.tree, "org.lineageos.platform.internal.R",
                  "com.android.internal.R", "*.java")
globalFindReplace(args.tree, "org.lineageos.platform.internal.R",
                  "com.android.internal.R", "*.kt")

if is_legacy_tree:
    globalFindReplace(args.tree, "org.lineageos.platform.internal",
                    "VendorSupport-preference", "*.mk")
    globalFindReplace(args.tree, "org.lineageos.platform.internal",
                    "VendorSupport-preference", "*.bp")
    globalFindReplace(args.tree, "org.lineageos.internal.util",
                    "com.libremobileos.support.util", "*.java")
    globalFindReplace(args.tree, "org.lineageos.internal.util",
                    "com.libremobileos.support.util", "*.kt")

    globalFindReplace(args.tree, "lineageos.providers.LineageSettings",
                    "android.provider.Settings", "*.java")
    globalFindReplace(args.tree, "lineageos.providers.LineageSettings",
                    "android.provider.Settings", "*.kt")

    globalFindReplace(args.tree, "LineageSettings",
                    "Settings", "*.java")
    globalFindReplace(args.tree, "LineageSettings",
                    "Settings", "*.kt")

    globalFindReplace(args.tree, "lineageos.hardware.",
                    "com.android.internal.libremobileos.hardware.", "*.java")
    globalFindReplace(args.tree, "lineageos.hardware.",
                    "com.android.internal.libremobileos.hardware.", "*.kt")
    globalFindReplace(args.tree, "LiveDisplayManager.getInstance(context)",
                    "context.getSystemService(LiveDisplayManager.java)", "*.java")
    globalFindReplace(args.tree, "LiveDisplayManager.getInstance(context)",
                    "context.getSystemService(LiveDisplayManager::class.java)", "*.kt")
else:
    globalFindReplace(args.tree, "org.lineageos.platform.internal",
                    "framework-lmodroid.static", "*.mk")
    globalFindReplace(args.tree, "org.lineageos.platform.internal",
                    "framework-lmodroid.static", "*.bp")
    globalFindReplace(args.tree, "org.lineageos.internal.util",
                    "com.libremobileos.util", "*.java")
    globalFindReplace(args.tree, "org.lineageos.internal.util",
                    "com.libremobileos.util", "*.kt")

    globalFindReplace(args.tree, "import lineageos.providers.LineageSettings;",
                    "import android.provider.Settings;", "*.java", append_lines=["import com.libremobileos.providers.LMOSettings;"])
    globalFindReplace(args.tree, "import lineageos.providers.LineageSettings",
                    "import android.provider.Settings", "*.kt", append_lines=["import com.libremobileos.providers.LMOSettings"])
    globalFindReplace(args.tree, "lineageos.providers.LineageSettings",
                    "com.libremobileos.providers.LMOSettings", "*.java")
    globalFindReplace(args.tree, "lineageos.providers.LineageSettings",
                    "com.libremobileos.providers.LMOSettings", "*.kt")

    globalFindReplace(args.tree, "LineageSettings.System.get",
                    "Setnothing.System.get", "*.java")
    globalFindReplace(args.tree, "LineageSettings.System.get",
                    "Setnothing.System.get", "*.kt")
    globalFindReplace(args.tree, "LineageSettings.System.put",
                    "Setnothing.System.put", "*.java")
    globalFindReplace(args.tree, "LineageSettings.System.put",
                    "Setnothing.System.put", "*.kt")

    globalFindReplace(args.tree, "LineageSettings.Secure.get",
                    "Setnothing.Secure.get", "*.java")
    globalFindReplace(args.tree, "LineageSettings.Secure.get",
                    "Setnothing.Secure.get", "*.kt")
    globalFindReplace(args.tree, "LineageSettings.Secure.put",
                    "Setnothing.Secure.put", "*.java")
    globalFindReplace(args.tree, "LineageSettings.Secure.put",
                    "Setnothing.Secure.put", "*.kt")

    globalFindReplace(args.tree, "LineageSettings.Global.get",
                    "Setnothing.Global.get", "*.java")
    globalFindReplace(args.tree, "LineageSettings.Global.get",
                    "Setnothing.Global.get", "*.kt")
    globalFindReplace(args.tree, "LineageSettings.Global.put",
                    "Setnothing.Global.put", "*.java")
    globalFindReplace(args.tree, "LineageSettings.Global.put",
                    "Setnothing.Global.put", "*.kt")

    globalFindReplace(args.tree, "LineageSettings",
                    "LMOSettings", "*.java")
    globalFindReplace(args.tree, "LineageSettings",
                    "LMOSettings", "*.kt")

    globalFindReplace(args.tree, "Setnothing",
                    "Settings", "*.java")
    globalFindReplace(args.tree, "Setnothing",
                    "Settings", "*.kt")

    globalFindReplace(args.tree, "lineageos.hardware.",
                    "com.libremobileos.hardware.", "*.java")
    globalFindReplace(args.tree, "lineageos.hardware.",
                    "com.libremobileos.hardware.", "*.kt")


globalRemoveDuplicateLines(args.tree, "android.provider.Settings;", "*.java")
globalRemoveDuplicateLines(args.tree, "import android.provider.Settings", "*.kt")

# LineageOS intents
if is_legacy_tree:
    globalFindReplace(args.tree, "lineageos.content.Intent.ACTION_INITIALIZE_LINEAGE_HARDWARE",
                    '"lineageos.intent.action.INITIALIZE_LINEAGE_HARDWARE"', "*.java")
    globalFindReplace(args.tree, "lineageos.content.Intent.ACTION_INITIALIZE_LINEAGE_HARDWARE",
                    '"lineageos.intent.action.INITIALIZE_LINEAGE_HARDWARE"', "*.kt")
    globalFindReplace(args.tree, "lineageos.content.Intent",
                    "Intent", "*.java")
    globalFindReplace(args.tree, "lineageos.content.Intent",
                    "Intent", "*.kt")
else:
    globalFindReplace(args.tree, "lineageos.content.Intent",
                    "com.libremobileos.content.Intent", "*.java")
    globalFindReplace(args.tree, "lineageos.content.Intent",
                    "com.libremobileos.content.Intent", "*.kt")

# Reduce partition sizes
globalReduceReservedSize(args.tree)
