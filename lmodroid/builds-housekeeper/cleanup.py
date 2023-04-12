#!/usr/bin/env python3

import argparse
import os
import shutil
from datetime import datetime

parser = argparse.ArgumentParser()
parser.add_argument(
    "builds", help="Path to builds dir.")
args = parser.parse_args()

builds = {}
to_remove = []
for (dirpath, dirnames, filenames) in os.walk(os.path.join(args.builds, "full")):
    for filename in filenames:
        if filename.endswith(".zip"):
            _, version, builddate, buildtype, device = os.path.splitext(filename)[0].split('-')
            version_major, version_minor = version.split('.')
            if device not in builds:
                builds[device] = {}
            if version_major not in builds[device]:
                builds[device][version_major] = {}
                builds[device][version_major]["dirs"] = []
            builds[device][version_major]["dirs"].append(dirpath)

for device in builds:
    version_idx = 0
    sorted_versions = sorted(
        builds[device], key=lambda x: int(x), reverse=True)
    for version in sorted_versions:
        builds[device][version]["dirs"].sort(
            key=lambda date: datetime.strptime(
                date.split('/')[-1], "%Y%m%d"), reverse=True)

        build_idx = 0
        for dir in builds[device][version]["dirs"]:
            if version_idx > 0:
                if build_idx > 0:
                    to_remove.append(dir)
            else:
                if build_idx > 2:
                    to_remove.append(dir)
            build_idx += 1
        version_idx += 1

for dir in to_remove:
    print("Removing " + dir)
    shutil.rmtree(dir)
