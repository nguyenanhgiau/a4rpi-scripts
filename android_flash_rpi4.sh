#!/bin/bash

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

if [ -z ${ANDROID_PRODUCT_OUT} ]; then
	echo "You must run lunch first"
	exit 1
fi

if [ $# -ne 1 ]; then
        echo "Usage: $0 [drive]"
        echo "       drive is 'sdb', 'mmcblk0'"
        exit 1
fi

DRIVE=$1

if [ -z ${TARGET_PRODUCT} ]; then
	echo "Please run 'lunch' first"
	exit
fi

# Check the drive exists in /sys/block
if [ ! -e /sys/block/${DRIVE}/size ]; then
	echo "Drive does not exist"
	exit 1
fi

# Check it is a flash drive (size < 32MiB)
NUM_SECTORS=`cat /sys/block/${DRIVE}/size`
if [ $NUM_SECTORS -eq 0 -o $NUM_SECTORS -gt 64000000 ]; then
	echo "Does not look like an SD card, bailing out"
	exit 1
fi

# Unmount any partitions that have been automounted
if [ $DRIVE == "mmcblk0" ]; then
	sudo umount /dev/${DRIVE}*
	BOOT_PART=/dev/${DRIVE}p1
	SYSTEM_PART=/dev/${DRIVE}p2
	VENDOR_PART=/dev/${DRIVE}p3
	USER_PART=/dev/${DRIVE}p4
else
	sudo umount /dev/${DRIVE}[1-9]
	BOOT_PART=/dev/${DRIVE}1
	SYSTEM_PART=/dev/${DRIVE}2
	VENDOR_PART=/dev/${DRIVE}3
	USER_PART=/dev/${DRIVE}4
fi

sleep 2

# Overwite any existing partiton table with zeros
sudo dd if=/dev/zero of=/dev/${DRIVE} bs=1M count=10
if [ $? -ne 0 ]; then echo "Error: dd"; exit 1; fi

# Create 4 partitions
# Device     Boot   Start      End  Sectors  Size Id Type
# /dev/sdb1  *       2048   264191   262144  128M  c W95 FAT32 (LBA)
# /dev/sdb2        264192  2361343  2097152    1G 83 Linux
# /dev/sdb3       2361344  2623487   262144  128M 83 Linux
# /dev/sdb4       2623488 31116287 28492800 13,6G 83 Linux
# Note that the parameters to sfdisk changed slightly v2.26
SFDISK_VERSION=`sfdisk --version | awk '{print $4}'`
if version_gt $SFDISK_VERSION "2.26"; then
	sudo sfdisk /dev/${DRIVE} << EOF
,128M,0x0c,*
,1600M,L,
,128M,L,
,,L,
EOF
else
	sudo sfdisk --unit M /dev/${DRIVE} << EOF
,128M,0x0c,*
,1600M,L,
,128M,L,
,,L,
EOF
fi
if [ $? -ne 0 ]; then echo "Error: sdfisk"; exit 1; fi

# Format p1 with FAT32
sudo mkfs.vfat -F 32 -n boot ${BOOT_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.vfat"; exit 1; fi
# Format p2,3,4 with ext4
yes | sudo mkfs.ext4 -L system ${SYSTEM_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.ext4"; exit 1; fi
yes | sudo mkfs.ext4 -L vendor ${VENDOR_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.ext4"; exit 1; fi
yes | sudo mkfs.ext4 -L data ${USER_PART}
if [ $? -ne 0 ]; then echo "Error: mkfs.ext4"; exit 1; fi
echo "SUCCESS! Your microSD card has been formatted"

echo "Writing system & vendor partition..."
sudo dd if=${ANDROID_PRODUCT_OUT}/system.img of=${SYSTEM_PART} bs=1M
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo dd if=${ANDROID_PRODUCT_OUT}/vendor.img of=${VENDOR_PART} bs=1M
if [ $? != 0 ]; then echo "ERROR"; exit; fi

echo "Copying kernel & ramdisk to BOOT partition..."
sudo mount ${BOOT_PART} /mnt
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo cp ${ANDROID_BUILD_TOP}/device/brcm/rpi4/boot/* /mnt
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo cp ${ANDROID_BUILD_TOP}/kernel/prebuilts/4.19/arm64/Image.gz /mnt
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo cp ${ANDROID_PRODUCT_OUT}/obj/KERNEL_OBJ/arch/arm64/boot/dts/broadcom/*.dtb /mnt
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo mkdir /mnt/overlays
sudo cp ${ANDROID_PRODUCT_OUT}/obj/KERNEL_OBJ/arch/arm64/boot/dts/overlays/*.dtbo /mnt/overlays
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sudo cp ${ANDROID_PRODUCT_OUT}/ramdisk.img /mnt
if [ $? != 0 ]; then echo "ERROR"; exit; fi

sync
sudo umount /mnt

echo "SUCCESS! Andrdoid4RPi installed on the uSD card. Enjoy"

exit 0

