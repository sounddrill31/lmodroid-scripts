#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

echo DEVICE=$DEVICE
echo ROM_VERSION=$ROM_VERSION
echo BUILD_TYPE=$BUILD_TYPE
echo LMODROID_BUILDTYPE=$LMODROID_BUILDTYPE
echo RELEASE_TYPE=$RELEASE_TYPE
echo CCACHE_DIR=$CCACHE_DIR
echo ROOTDIR=$ROOTDIR
echo WORKSPACE=$WORKSPACE

cd $ROOTDIR

echo '[+] Setup Environment...'
. build/envsetup.sh

echo '[+] Breakfast...'
breakfast lmodroid_${DEVICE}${RELEASE_TYPE}-${BUILD_TYPE}

echo '[+] Cleaning...'
rm -rf $ROOTDIR/out

echo '[+] Making ROM...'
make bacon -j$(nproc --all)

if [[ ! $? -eq 0 ]]; then
    echo '[+] Cleaning...'
    rm -rf $ROOTDIR/*

    exit 1
fi
