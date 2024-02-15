#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

cd $ROOTDIR

BUILT_ROM_PATH=`ls $ROOTDIR/out/target/product/${DEVICE}/LMODroid-*.zip`
if [[ $? -eq 0 ]]; then
    echo "[+] Built Rom: ${BUILT_ROM_PATH}"
    DATETIME=`echo ${BUILT_ROM_PATH%.zip} | cut -f 3 -d '-'`
    BUILT_IMAGES="boot recovery dtbo vendor_boot super_empty vendor_kernel_boot init_boot vbmeta"
    TARGETFILES=`find out/target/product/${DEVICE}/obj/PACKAGING/target_files_intermediates/ -maxdepth 1 -type d  | grep target_files-`

    echo "[+] Upload ROM to OTA server."
    ssh -p 40048 -o StrictHostKeyChecking=no root@get.libremobileos.com mkdir -p /root/builds/full/${DEVICE}/${DATETIME}
    rsync -avz "--rsh=ssh -p 40048 -o StrictHostKeyChecking=no" \
        ${BUILT_ROM_PATH} \
        root@get.libremobileos.com:/root/builds/full/${DEVICE}/${DATETIME}

    for IMAGE in $BUILT_IMAGES; do
        if [ -f $TARGETFILES/IMAGES/$IMAGE.img ]; then
            echo "[+] Upload $IMAGE to OTA server."
            rsync -avz "--rsh=ssh -p 40048 -o StrictHostKeyChecking=no" \
                $TARGETFILES/IMAGES/$IMAGE.img \
                root@get.libremobileos.com:/root/builds/full/${DEVICE}/${DATETIME}
        fi
    done
else
    echo '[+] Cleaning...'
    rm -rf $ROOTDIR/*

    exit 1
fi

echo '[+] Cleaning...'
rm -rf $ROOTDIR/*

exit 0
