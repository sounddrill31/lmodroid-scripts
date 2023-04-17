#!/usr/bin/env python3

import argparse
import glob

parser = argparse.ArgumentParser()
parser.add_argument(
    "tree", help="Lineage hardware tree.")
args = parser.parse_args()


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

# Fix Doze resources lib
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.mk")
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.bp")

# Fix lineageos.internal dependency
globalFindReplace(args.tree, "org.lineageos.platform.internal",
                  "VendorSupport-preference", "*.mk")
globalFindReplace(args.tree, "org.lineageos.platform.internal",
                  "VendorSupport-preference", "*.bp")
globalFindReplace(args.tree, "org.lineageos.internal.util",
                  "com.libremobileos.support.util", "*.java")
globalFindReplace(args.tree, "org.lineageos.internal.util",
                  "com.libremobileos.support.util", "*.kt")
globalFindReplace(args.tree, "org.lineageos.platform.internal.R",
                  "com.android.internal.R", "*.java")
globalFindReplace(args.tree, "org.lineageos.platform.internal.R",
                  "com.android.internal.R", "*.kt")
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

globalRemoveDuplicateLines(args.tree, "android.provider.Settings;", "*.java")
globalRemoveDuplicateLines(args.tree, "import android.provider.Settings", "*.kt")

# LineageOS intents
globalFindReplace(args.tree, "lineageos.content.Intent.ACTION_INITIALIZE_LINEAGE_HARDWARE",
                  '"lineageos.intent.action.INITIALIZE_LINEAGE_HARDWARE"', "*.java")
globalFindReplace(args.tree, "lineageos.content.Intent.ACTION_INITIALIZE_LINEAGE_HARDWARE",
                  '"lineageos.intent.action.INITIALIZE_LINEAGE_HARDWARE"', "*.kt")
globalFindReplace(args.tree, "lineageos.content.Intent",
                  "Intent", "*.java")
globalFindReplace(args.tree, "lineageos.content.Intent",
                  "Intent", "*.kt")
