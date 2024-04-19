import argparse
import json
import subprocess
import sys
import yaml


parser = argparse.ArgumentParser()
parser.add_argument('device', type=str, help='Device to update')
parser.add_argument('branch_src', type=str, help='Branch of the source repo')
parser.add_argument('branch_dist', type=str,
                    help='Branch of the destination repo')
args = parser.parse_args()
full_branch = ":".join((args.branch_src, args.branch_dist))

with open("device_deps.json") as f:
    device_deps = json.load(f)

with open("lineage-devices-updater/devices.json") as f:
    updater_devices = json.load(f)

with open("los-gerrit-config/structure.yml", "r") as f:
    los_repos = yaml.load(f.read(), Loader=yaml.BaseLoader)

with open("gerrit-config/structure.yml", "r") as f:
    lmo_repos = yaml.load(f.read(), Loader=yaml.BaseLoader)

try:
    if updater_devices[full_branch][args.device]:
        print("Device {device} is already forked".format(device=args.device))
        sys.exit(0)
except KeyError:
    pass

repos = []
for repo in device_deps[args.device]:
    if repo.startswith("android_device") and "sepolicy" not in repo:
        repos.append("LineageOS/" + repo)

new_repos=[]
for r in repos:
    new_repos.append(r.replace("LineageOS/android_", "LMODroid-Devices/"))
if full_branch not in updater_devices:
    updater_devices[full_branch] = {}
for repo in repos:
    for updater_device in updater_devices[full_branch]:
        if repo in updater_devices[full_branch][updater_device]:
            new_repos.remove(repo.replace(
                "LineageOS/android_", "LMODroid-Devices/"))
            break

updater_devices[full_branch][args.device] = repos

with open("lineage-devices-updater/devices.json", 'w') as f:
    json.dump(updater_devices, f, indent=4, sort_keys=True)

def get_parent(repo):
    for parent, children in los_repos.items():
        for child in children:
            if child == repo:
                return parent
    return None

def find_real_parent(repo):
    parent = get_parent(repo)
    if parent is None or parent.startswith("Lineage-"):
        return None
    if parent.startswith("OEM-"):
        return repo
    return find_real_parent(parent)

def is_child_avaliable(repo):
    for parent, children in lmo_repos.items():
        if parent == repo:
            return True
        for child in children:
            if child == repo:
                return True
    return False

for repo in new_repos:
    if not is_child_avaliable(repo):
        real_parent = find_real_parent(repo.replace(
            "LMODroid-Devices/", "LineageOS/android_"))
        if real_parent is None:
            continue
        parent = "LMODroid-DEVICE-" + real_parent
        if parent not in lmo_repos["LMODroid-Device-Projects"]:
            lmo_repos["LMODroid-Device-Projects"].append(parent)
        if parent not in lmo_repos:
            lmo_repos.update({ parent : [ repo ] })
        else:
            lmo_repos[parent].append(repo)

with open("gerrit-config/structure.yml", 'w') as yamlfile:
    yamlfile.write("---\n")
    stream = yaml.safe_dump(lmo_repos, default_flow_style=False)
    yamlfile.write(stream.replace('- ', '  - '))

for repo in new_repos:
    process = subprocess.run(["./fork-and-push.sh", repo.replace(
        "LMODroid-Devices/", "LineageOS/android_"), args.branch_src,
        repo, args.branch_dist], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(process.stderr.decode("utf-8").strip())
    print(process.stdout.decode('utf-8').strip())
