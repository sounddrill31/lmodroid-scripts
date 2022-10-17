#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

cd $ROOTDIR

BUILT_ROM_PATH=`ls $ROOTDIR/out/target/product/${DEVICE}/LMODroid-*.zip`
if [[ $? -eq 0 ]]; then
    echo "[+] Built Rom: ${BUILT_ROM_PATH}"
    ROM_BASENAME=`basename ${BUILT_ROM_PATH} ".zip"`
    RECOVERY_NAME=`echo "${ROM_BASENAME}.img" | sed "s/-${DEVICE}/-recovery-${DEVICE}/"`

    RECOVERYIMG=boot.img
    if [[ -f $ROOTDIR/out/target/product/$DEVICE/recovery.img ]]; then
        RECOVERYIMG=recovery.img
    fi

    echo "[+] Upload ROM to OTA server."
    rsync -avz "--rsh=ssh -p 40048 -o StrictHostKeyChecking=no" \
        ${BUILT_ROM_PATH} \
        root@get.libremobileos.com:/root/builds/full/

    echo "[+] Upload Recovery to OTA server."
    rsync -avz "--rsh=ssh -p 40048 -o StrictHostKeyChecking=no" \
        $ROOTDIR/out/target/product/$DEVICE/${RECOVERYIMG} \
        root@get.libremobileos.com:/root/builds/recovery/${RECOVERY_NAME}
else
    exit 1
fi
exit 0
