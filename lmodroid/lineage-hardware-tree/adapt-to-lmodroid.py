#!/usr/bin/env python3

import argparse
import glob
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument(
    "tree", help="Lineage hardware tree.")
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

# Fix Doze resources lib
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.mk")
globalFindReplace(args.tree, "org.lineageos.settings.resources",
                  "com.libremobileos.settings.resources", "*.bp")

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
