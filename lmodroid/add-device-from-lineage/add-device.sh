#!/bin/bash

usage()
{
    echo "Usage: $0 <device> <branch_src> <branch_dist>"
}

if [ "$3" == "" ]; then
    echo "ERROR: Enter all needed parameters"
    usage
    exit 1
fi

export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
DEVICE=$1
BRANCH_SRC=$2
BRANCH_DIST=$3

if [[ ! -d scripts ]]; then
    git clone https://github.com/LineageOS/scripts.git
else
    git -C scripts fetch origin
    git -C scripts reset --hard origin/master
fi

if [[ ! -d los-gerrit-config ]]; then
    git clone https://github.com/lineageos-infra/gerrit-config.git los-gerrit-config
else
    git -C los-gerrit-config fetch origin
    git -C los-gerrit-config reset --hard origin/main
fi

if [[ ! -d lineage-devices-updater ]]; then
    git clone ssh://git@git.libremobileos.com:40057/infrastructure/lineage-devices-updater.git
else
    git -C lineage-devices-updater fetch origin
    git -C lineage-devices-updater reset --hard origin/main
fi

if [[ ! -d gerrit-config ]]; then
    git clone ssh://git@git.libremobileos.com:40057/infrastructure/gerrit-config.git
else
    git -C gerrit-config fetch origin
    git -C gerrit-config reset --hard origin/main
fi

if [[ -z "$GERRIT_USER" ]]; then
    echo "ERROR: Set the GERRIT_USER environment variable"
    exit 1
fi
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "ERROR: Set the GITHUB_TOKEN environment variable"
    exit 1
fi
echo "$GITHUB_TOKEN" > token

if [[ ! -f device_deps.json ]]; then
    pip install -r scripts/device-deps-regenerator/requirements.txt
    python scripts/device-deps-regenerator/app.py -j 8
    python scripts/device-deps-regenerator/devices.py
fi

if [[ ! -f device_deps.json ]]; then
    echo "ERROR: Lineage device_deps.json not found"
    exit 1
fi

python add-repos.py ${DEVICE} ${BRANCH_SRC} ${BRANCH_DIST}

git -C gerrit-config add -A
git -C gerrit-config commit -a -m "Add ${DEVICE} by device add script" && git -C gerrit-config push origin HEAD:refs/heads/main

git -C lineage-devices-updater add -A
git -C lineage-devices-updater commit -a -m "Add ${DEVICE} by device add script" && git -C lineage-devices-updater push origin HEAD:refs/heads/main
