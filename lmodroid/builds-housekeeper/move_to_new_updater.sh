#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

BUILDS_DIR=$1
RECOVERY_DIR=$2
NEW_DIR=$3

for build in $BUILDS_DIR/*.zip; do
    FILE=${build%.zip}
    FILE=${FILE##*/}
    DEVICE=`echo $FILE | cut -f 5 -d '-'`
    DATE=`echo $FILE | cut -f 3 -d '-'`

    mkdir -p $NEW_DIR/$DEVICE/$DATE
    mv $build $NEW_DIR/$DEVICE/$DATE/
done

for recovery in $RECOVERY_DIR/*.img; do
    FILE=${recovery%.img}
    FILE=${FILE##*/}
    DEVICE=`echo $FILE | cut -f 6 -d '-'`
    DATE=`echo $FILE | cut -f 3 -d '-'`

    if [ -d $NEW_DIR/$DEVICE/$DATE ]; then
        mv $recovery $NEW_DIR/$DEVICE/$DATE/recovery.img
    fi
done
