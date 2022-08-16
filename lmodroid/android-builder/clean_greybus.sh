#!/bin/bash

KERNELS_PATH=$1

mv_and_commit() {
	MK_PATH=$1
	KERNEL_PATH=`echo $MK_PATH | sed 's|/drivers/staging/greybus/tools/Android.mk||'`
	if [[ ! -f ${KERNEL_PATH}/Android.mk ]]; then
		echo "Patching $MK_PATH"
		mv $MK_PATH ${MK_PATH}_bak

		git -C $KERNEL_PATH add ${MK_PATH}_bak
		git -C $KERNEL_PATH commit -m "Cleanup ${MK_PATH}"
	fi
}
export -f mv_and_commit

find $KERNELS_PATH -wholename '*/drivers/staging/greybus/tools/Android.mk' -exec bash -c 'mv_and_commit "$0"' {} \;
