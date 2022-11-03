#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

if ! command -v repo &> /dev/null
then
    mkdir -p ${JENKINS_HOME}/bin
    curl https://storage.googleapis.com/git-repo-downloads/repo > ${JENKINS_HOME}/bin/repo
    chmod a+rx ${JENKINS_HOME}/bin/repo
fi

if [[ ! -d $ROOTDIR ]]; then
    echo "ROOTDIR: $ROOTDIR not found"
    mkdir -p $ROOTDIR
    cd $ROOTDIR
    repo init -u https://git.libremobileos.com/LMODroid/manifest.git -b $ROM_VERSION -g default,-darwin --depth=1
    mkdir -p .repo/local_manifests
    git clone https://git.libremobileos.com/ninja-turtles/manifest.git -b $ROM_VERSION .repo/turtles_manifest
    git clone ssh://git@git.libremobileos.com:40057/LMODroid-priv/manifest.git -b $ROM_VERSION .repo/lmo_private_manifest
    ln -s ../turtles_manifest/manifest.xml .repo/local_manifests/turtles.xml
    ln -s ../lmo_private_manifest/manifest.xml .repo/local_manifests/private.xml
else
    cd $ROOTDIR
fi

echo '[+] Syncing repos...'
git -C .repo/turtles_manifest fetch origin
git -C .repo/turtles_manifest reset --hard origin/$ROM_VERSION
git -C .repo/lmo_private_manifest fetch origin
git -C .repo/lmo_private_manifest reset --hard origin/$ROM_VERSION
rm -rf .repo/local_manifests/roomservice.xml
repo sync --force-sync -c -j8 --no-clone-bundle --no-tags --force-remove-dirty
