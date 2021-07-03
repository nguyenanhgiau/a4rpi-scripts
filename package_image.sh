#!/bin/bash

# Check image output
if [ -z ${ANDROID_PRODUCT_OUT} ]; then
	echo "You must run lunch first"
	exit 1
fi

if [ -z ${TARGET_PRODUCT} ]; then
	echo "Please run 'lunch' first"
	exit 1
fi

# Create folder contains your image
PACKAGE_IMG_DIR=${ANDROID_BUILD_TOP}/android_image
mkdir ${PACKAGE_IMG_DIR}

cd ${ANDROID_BUILD_TOP}
echo "Copying android image..."
cp --parents out/target/product/rpi4/system.img ${PACKAGE_IMG_DIR}
cp --parents out/target/product/rpi4/vendor.img ${PACKAGE_IMG_DIR}
cp --parents out/target/product/rpi4/ramdisk.img ${PACKAGE_IMG_DIR}
echo "Copying kernel image..."
cp --parents -r device/arpi/rpi4/boot/ ${PACKAGE_IMG_DIR}
cp --parents scripts/kernel-android-S/arpi/arch/arm64/boot/Image.gz ${PACKAGE_IMG_DIR}
cp --parents scripts/kernel-android-S/arpi/arch/arm64/boot/dts/broadcom/bcm2711-rpi-*.dtb ${PACKAGE_IMG_DIR}
mkdir ${PACKAGE_IMG_DIR}/overlays
cp --parents scripts/kernel-android-S/arpi/arch/arm64/boot/dts/overlays/vc4-kms-v3d-pi4.dtbo ${PACKAGE_IMG_DIR}

echo "Copying script flash for rpi4"
sed '2 a ANDROID_BUILD_TOP=.\nANDROID_PRODUCT_OUT=./out/target/product/rpi4\nTARGET_PRODUCT=rpi4' ${ANDROID_BUILD_TOP}/scripts/android_flash_rpi4.sh \
	> ${PACKAGE_IMG_DIR}/android_flash_rpi4.sh
chmod a+x ${PACKAGE_IMG_DIR}/android_flash_rpi4.sh

echo "Your image is located at ${ANDROID_BUILD_TOP}/android_image"
echo "Now, you can download it and flash image to sdcard at local machine"
echo "Package done!!!"