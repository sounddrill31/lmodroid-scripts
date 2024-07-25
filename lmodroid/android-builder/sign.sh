#!/bin/bash

LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
. $LOCALDIR/config.sh

cd $ROOTDIR

TARGETFILES=`find out/target/product/${DEVICE}/obj/PACKAGING/target_files_intermediates/ -mindepth 1 -maxdepth 1 -type d`
if [[ ! -d $TARGETFILES ]]; then
    echo '[+] Cleaning...'
    rm -rf $ROOTDIR/*

    exit 1
fi

. build/envsetup.sh
breakfast ${DEVICE} ${BUILD_TYPE}
LMODROID_BUILD_NAME=$(get_build_var LMODROID_BUILD_NAME)

sign_target_files_apks -o -d ${KEYS_DIR} \
    --extra_apks AdServicesApk.apk=${KEYS_DIR}/releasekey \
    --extra_apks FederatedCompute.apk=${KEYS_DIR}/releasekey \
    --extra_apks HalfSheetUX.apk=${KEYS_DIR}/releasekey \
    --extra_apks HealthConnectBackupRestore.apk=${KEYS_DIR}/releasekey \
    --extra_apks HealthConnectController.apk=${KEYS_DIR}/releasekey \
    --extra_apks OsuLogin.apk=${KEYS_DIR}/releasekey \
    --extra_apks SafetyCenterResources.apk=${KEYS_DIR}/releasekey \
    --extra_apks ServiceConnectivityResources.apk=${KEYS_DIR}/releasekey \
    --extra_apks ServiceUwbResources.apk=${KEYS_DIR}/releasekey \
    --extra_apks ServiceWifiResources.apk=${KEYS_DIR}/releasekey \
    --extra_apks WifiDialog.apk=${KEYS_DIR}/releasekey \
    --extra_apks com.android.adbd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adbd \
    --extra_apks com.android.adservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adservices \
    --extra_apks com.android.adservices.api.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adservices.api \
    --extra_apks com.android.appsearch.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.appsearch \
    --extra_apks com.android.art.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.art \
    --extra_apks com.android.bluetooth.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.bluetooth \
    --extra_apks com.android.btservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.btservices \
    --extra_apks com.android.cellbroadcast.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.cellbroadcast \
    --extra_apks com.android.compos.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.compos \
    --extra_apks com.android.configinfrastructure.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.configinfrastructure \
    --extra_apks com.android.connectivity.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.connectivity.resources \
    --extra_apks com.android.conscrypt.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.conscrypt \
    --extra_apks com.android.devicelock.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.devicelock \
    --extra_apks com.android.extservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.extservices \
    --extra_apks com.android.graphics.pdf.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.graphics.pdf \
    --extra_apks com.android.hardware.biometrics.face.virtual.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.biometrics.face.virtual \
    --extra_apks com.android.hardware.biometrics.fingerprint.virtual.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.biometrics.fingerprint.virtual \
    --extra_apks com.android.hardware.boot.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.boot \
    --extra_apks com.android.hardware.cas.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.cas \
    --extra_apks com.android.hardware.wifi.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.wifi \
    --extra_apks com.android.healthfitness.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.healthfitness \
    --extra_apks com.android.hotspot2.osulogin.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hotspot2.osulogin \
    --extra_apks com.android.i18n.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.i18n \
    --extra_apks com.android.ipsec.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.ipsec \
    --extra_apks com.android.media.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.media \
    --extra_apks com.android.media.swcodec.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.media.swcodec \
    --extra_apks com.android.mediaprovider.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.mediaprovider \
    --extra_apks com.android.nearby.halfsheet.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.nearby.halfsheet \
    --extra_apks com.android.networkstack.tethering.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.networkstack.tethering \
    --extra_apks com.android.neuralnetworks.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.neuralnetworks \
    --extra_apks com.android.ondevicepersonalization.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.ondevicepersonalization \
    --extra_apks com.android.os.statsd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.os.statsd \
    --extra_apks com.android.permission.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.permission \
    --extra_apks com.android.resolv.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.resolv \
    --extra_apks com.android.rkpd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.rkpd \
    --extra_apks com.android.runtime.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.runtime \
    --extra_apks com.android.safetycenter.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.safetycenter.resources \
    --extra_apks com.android.scheduling.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.scheduling \
    --extra_apks com.android.sdkext.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.sdkext \
    --extra_apks com.android.support.apexer.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.support.apexer \
    --extra_apks com.android.telephony.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.telephony \
    --extra_apks com.android.telephonymodules.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.telephonymodules \
    --extra_apks com.android.tethering.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.tethering \
    --extra_apks com.android.tzdata.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.tzdata \
    --extra_apks com.android.uwb.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.uwb \
    --extra_apks com.android.uwb.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.uwb.resources \
    --extra_apks com.android.virt.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.virt \
    --extra_apks com.android.vndk.current.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.vndk.current \
    --extra_apks com.android.vndk.current.on_vendor.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.vndk.current.on_vendor \
    --extra_apks com.android.wifi.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi \
    --extra_apks com.android.wifi.dialog.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi.dialog \
    --extra_apks com.android.wifi.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi.resources \
    --extra_apks com.google.pixel.camera.hal.apex=vendor/lmodroid-priv/keys/apex-keys/com.google.pixel.camera.hal \
    --extra_apks com.google.pixel.vibrator.hal.apex=vendor/lmodroid-priv/keys/apex-keys/com.google.pixel.vibrator.hal \
    --extra_apks com.qorvo.uwb.apex=vendor/lmodroid-priv/keys/apex-keys/com.qorvo.uwb \
    --extra_apex_payload_key com.android.adbd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adbd.pem \
    --extra_apex_payload_key com.android.adservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adservices.pem \
    --extra_apex_payload_key com.android.adservices.api.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.adservices.api.pem \
    --extra_apex_payload_key com.android.appsearch.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.appsearch.pem \
    --extra_apex_payload_key com.android.art.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.art.pem \
    --extra_apex_payload_key com.android.bluetooth.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.bluetooth.pem \
    --extra_apex_payload_key com.android.btservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.btservices.pem \
    --extra_apex_payload_key com.android.cellbroadcast.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.cellbroadcast.pem \
    --extra_apex_payload_key com.android.compos.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.compos.pem \
    --extra_apex_payload_key com.android.configinfrastructure.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.configinfrastructure.pem \
    --extra_apex_payload_key com.android.connectivity.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.connectivity.resources.pem \
    --extra_apex_payload_key com.android.conscrypt.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.conscrypt.pem \
    --extra_apex_payload_key com.android.devicelock.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.devicelock.pem \
    --extra_apex_payload_key com.android.extservices.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.extservices.pem \
    --extra_apex_payload_key com.android.graphics.pdf.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.graphics.pdf.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.face.virtual.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.biometrics.face.virtual.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.fingerprint.virtual.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.biometrics.fingerprint.virtual.pem \
    --extra_apex_payload_key com.android.hardware.boot.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.boot.pem \
    --extra_apex_payload_key com.android.hardware.cas.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.cas.pem \
    --extra_apex_payload_key com.android.hardware.wifi.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hardware.wifi.pem \
    --extra_apex_payload_key com.android.healthfitness.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.healthfitness.pem \
    --extra_apex_payload_key com.android.hotspot2.osulogin.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.hotspot2.osulogin.pem \
    --extra_apex_payload_key com.android.i18n.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.i18n.pem \
    --extra_apex_payload_key com.android.ipsec.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.ipsec.pem \
    --extra_apex_payload_key com.android.media.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.media.pem \
    --extra_apex_payload_key com.android.media.swcodec.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.media.swcodec.pem \
    --extra_apex_payload_key com.android.mediaprovider.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.mediaprovider.pem \
    --extra_apex_payload_key com.android.nearby.halfsheet.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.nearby.halfsheet.pem \
    --extra_apex_payload_key com.android.networkstack.tethering.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.networkstack.tethering.pem \
    --extra_apex_payload_key com.android.neuralnetworks.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.neuralnetworks.pem \
    --extra_apex_payload_key com.android.ondevicepersonalization.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.ondevicepersonalization.pem \
    --extra_apex_payload_key com.android.os.statsd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.os.statsd.pem \
    --extra_apex_payload_key com.android.permission.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.permission.pem \
    --extra_apex_payload_key com.android.resolv.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.resolv.pem \
    --extra_apex_payload_key com.android.rkpd.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.rkpd.pem \
    --extra_apex_payload_key com.android.runtime.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.runtime.pem \
    --extra_apex_payload_key com.android.safetycenter.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.safetycenter.resources.pem \
    --extra_apex_payload_key com.android.scheduling.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.scheduling.pem \
    --extra_apex_payload_key com.android.sdkext.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.sdkext.pem \
    --extra_apex_payload_key com.android.support.apexer.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.support.apexer.pem \
    --extra_apex_payload_key com.android.telephony.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.telephony.pem \
    --extra_apex_payload_key com.android.telephonymodules.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.telephonymodules.pem \
    --extra_apex_payload_key com.android.tethering.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.tethering.pem \
    --extra_apex_payload_key com.android.tzdata.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.tzdata.pem \
    --extra_apex_payload_key com.android.uwb.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.uwb.pem \
    --extra_apex_payload_key com.android.uwb.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.uwb.resources.pem \
    --extra_apex_payload_key com.android.virt.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.virt.pem \
    --extra_apex_payload_key com.android.vndk.current.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.vndk.current.pem \
    --extra_apex_payload_key com.android.vndk.current.on_vendor.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.vndk.current.on_vendor.pem \
    --extra_apex_payload_key com.android.wifi.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi.pem \
    --extra_apex_payload_key com.android.wifi.dialog.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi.dialog.pem \
    --extra_apex_payload_key com.android.wifi.resources.apex=vendor/lmodroid-priv/keys/apex-keys/com.android.wifi.resources.pem \
    --extra_apex_payload_key com.google.pixel.camera.hal.apex=vendor/lmodroid-priv/keys/apex-keys/com.google.pixel.camera.hal.pem \
    --extra_apex_payload_key com.google.pixel.vibrator.hal.apex=vendor/lmodroid-priv/keys/apex-keys/com.google.pixel.vibrator.hal.pem \
    --extra_apex_payload_key com.qorvo.uwb.apex=vendor/lmodroid-priv/keys/apex-keys/com.qorvo.uwb.pem \
    ${TARGETFILES}.zip \
    $ROOTDIR/out/target/product/${DEVICE}/${LMODROID_BUILD_NAME}-signed-target_files.zip

ota_from_target_files -k ${KEYS_DIR}/releasekey \
    --block --backup=true \
    $ROOTDIR/out/target/product/${DEVICE}/${LMODROID_BUILD_NAME}-signed-target_files.zip \
    $ROOTDIR/out/target/product/${DEVICE}/${LMODROID_BUILD_NAME}.zip

rm -rf $ROOTDIR/out/target/product/${DEVICE}/${LMODROID_BUILD_NAME}-signed-target_files.zip
//TODO: Use signed target files images on publish
