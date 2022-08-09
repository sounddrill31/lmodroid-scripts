#!/usr/bin/env python3

import argparse
import os
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
                builds[device][version_major]["full"] = []
                builds[device][version_major]["recovery"] = []
            builds[device][version_major]["full"].append(
                os.path.join(dirpath, filename))

for (dirpath, dirnames, filenames) in os.walk(os.path.join(args.builds, "recovery")):
    for filename in filenames:
        if filename.endswith(".img"):
            _, version, builddate, buildtype, rec, device = os.path.splitext(filename)[0].split('-')
            version_major, version_minor = version.split('.')
            if device not in builds:
                to_remove.append(os.path.join(dirpath, filename))
                continue
            if version_major not in builds[device]:
                to_remove.append(os.path.join(dirpath, filename))
                continue
            full_builds_dirpath = dirpath.replace("recovery", "full")
            full_build = "-".join([_, version, builddate,
                                  buildtype, device + ".zip"])
            if os.path.join(full_builds_dirpath, full_build) in builds[device][version_major]["full"]:
                builds[device][version_major]["recovery"].append(
                    os.path.join(dirpath, filename))
            else:
                to_remove.append(os.path.join(dirpath, filename))


for device in builds:
    version_idx = 0
    sorted_versions = sorted(
        builds[device], key=lambda x: int(x), reverse=True)
    for version in sorted_versions:
        for type in builds[device][version]:
            builds[device][version][type].sort(
                key=lambda date: datetime.strptime(
                    date.split('/')[-1].split('-')[2], "%Y%m%d"), reverse=True)
            build_idx = 0
            for build in builds[device][version][type]:
                if version_idx > 0:
                    if build_idx > 0:
                        to_remove.append(build)
                else:
                    if build_idx > 2:
                        to_remove.append(build)
                build_idx += 1
        version_idx += 1

for build in to_remove:
    print("Removing " + build)
    os.remove(build)
