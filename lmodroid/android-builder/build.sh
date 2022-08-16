#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

echo DEVICE=$DEVICE
echo ROM_VERSION=$ROM_VERSION
echo BUILD_TYPE=$BUILD_TYPE
echo LMODROID_BUILDTYPE=$LMODROID_BUILDTYPE
echo CCACHE_DIR=$CCACHE_DIR
echo ROOTDIR=$ROOTDIR
echo WORKSPACE=$WORKSPACE

cd $ROOTDIR

echo '[+] Setup Environment...'
. build/envsetup.sh

echo '[+] Breakfast...'
breakfast lmodroid_${DEVICE}-${BUILD_TYPE}

echo '[+] Patching greybus mk...'
$LOCALDIR/clean_greybus.sh kernel

echo '[+] Make Cleaning...'
make installclean -j$(nproc --all)
rm -rf $ROOTDIR/out/target/product/$DEVICE/*.zip
rm -rf $ROOTDIR/out/target/product/$DEVICE/system
rm -rf $ROOTDIR/out/target/product/$DEVICE/system_ext
rm -rf $ROOTDIR/out/target/product/$DEVICE/vendor
rm -rf $ROOTDIR/out/target/product/$DEVICE/product
rm -rf $ROOTDIR/out/target/product/$DEVICE/root
rm -rf $ROOTDIR/out/target/product/$DEVICE/recovery
rm -rf $ROOTDIR/out/target/product/$DEVICE/obj/PACKAGING/target_files_intermediates/*

echo '[+] Making ROM...'
make bacon -j$(nproc --all)
