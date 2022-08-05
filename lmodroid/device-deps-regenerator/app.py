import argparse
import concurrent.futures
import json
import traceback

from gitlab import Gitlab
from base64 import b64decode

parser = argparse.ArgumentParser()
parser.add_argument('-j', '--jobs', type=int, help='Max number of workers to use. Default is none')
args = parser.parse_args()

with open('token') as f:
    g = Gitlab("https://git.libremobileos.com", f.readline().strip())


# Group LMODroid-Devices
group_id = 10
group = g.groups.get(group_id)
projects = group.projects.list(all=True)

# supported branches, newest to oldest
CUR_BRANCHES = ['twelve', 'eleven']

def get_lmo_dependencies(repo):
    p = g.projects.get(repo)
    branch = None
    for b in CUR_BRANCHES:
        for br in p.branches.list(all=True):
            if b == br.name:
                branch = b
                break
        if branch is not None:
            break

    if branch is None:
        return None

    tree = p.repository_tree(ref=branch)
    blob_id = None
    for el in tree:
        if el["name"] == 'lmodroid.dependencies':
            blob_id = el["id"]
            break

    if blob_id is None:
        return [[], set()]

    deps = p.repository_raw_blob(blob_id)
    lmodeps = json.loads(deps.decode('utf-8'))

    mydeps = []
    non_device_repos = set()
    for el in lmodeps:
        if 'LMODroid-Devices' not in el['repository'] and "remote" not in el:
            non_device_repos.add(el['repository'])

        depbranch = el.get('branch', branch)
        if "remote" not in el:
            mydeps.append({'repo': el['repository'], 'branch': depbranch})

    return [mydeps, non_device_repos]

futures = {}
n = 1

dependencies = {}
other_repos = set()

with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
    for repo in projects:
        print(n, repo.attributes['path_with_namespace'])
        n += 1
        futures[executor.submit(
            get_lmo_dependencies, repo.attributes['path_with_namespace'])] = repo.attributes['path_with_namespace']
    for future in concurrent.futures.as_completed(futures):
        name = futures[future]
        try:
            data = future.result()
            if data is None:
                continue
            dependencies[name] = data[0]
            other_repos.update(data[1])
            print(name, "=>", data[0])
        except Exception as e:
            print('%r generated an exception: %s'%(name, e))
            traceback.print_exc()
            continue
    futures = {}

    print(other_repos)
    for name in other_repos:
        print(name)
        try:
            futures[executor.submit(
                get_lmo_dependencies, name)] = name
        except Exception:
            continue

    other_repos = {}
    for future in concurrent.futures.as_completed(futures):
        name = futures[future]
        try:
            data = future.result()
            if data is None:
                continue
            dependencies[name] = data[0]
            for el in data[1]:
                if el in dependencies:
                    continue
                other_repos.update(data[1])
            print(name, "=>", data[0])
        except Exception as e:
            print('%r generated an exception: %s'%(name, e))
            traceback.print_exc()
            continue
    futures = {}


print(other_repos)
#for name in other_repos:
#    dependencies[name] = get_lmo_dependencies(name)

with open('out.json', 'w') as f:
    json.dump(dependencies, f, indent=4)
