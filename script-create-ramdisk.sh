#!/bin/bash

# Description: this is a script for create ramdisk
# Author: neeyongliang
# Date: 2022.06.18 First release

set -e

fileName="rootfs.ramdisk"
gzFileName="rootfs.ramdisk.gz"
ubootFileName="rootfs.ramdisk.gz.uboot"
imgFileName="rootfs.img"

create_ramdisk() {
	if [ -f $fileName ]; then
		rm rootfs.ext*
	fi

	# generate image
	genext2fs -b 4096 -d rootfs $fileName

	# generate gzFileName
	gzip -9 $fileName

	# add ramdisk header
	mkimage \
		-n 'uboot ext2 ramdisk rootfs' \
		-A arm \
		-O linux \
		-T ramdisk \
		-C gzip \
		-d $gzFileName \
		$ubootFileName
}

create_ramdisk_by_qemu() {
	qemu-img create $imgFileName 22m
	mkfs.ext4 $imgFileName
	if [ -d /tmp/tempfs ]; then
		umount /tmp/tempfs > /dev/null 2>&1
		rm -rf /tmp/tempfs
	fi
	mkdir /tmp/tempfs
	mount -o loop $imgFileName /tmp/tempfs
	sleep 1
	rm -rf /tm/tempfs/*
	if [ -f "rootfs/root/.bash_history" ]; then
		rm rootfs/root/.bash_history
	fi
	cp -a rootfs/* /tmp/tempfs/
	sync
	sleep 1
	umount /tmp/tempfs/
}

if [ "$#" == 0 ]; then
	echo "Start create ramdisk..."
	create_ramdisk
elif [ "$1" == "qemu" ]; then
	echo "Start create ramdisk by qemu..."
	create_ramdisk_by_qemu
else
	echo "This script can create ramdisk, you can choose use qemu method."
	echo "Usage: $0 [qemu]"
fi