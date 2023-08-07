#!/bin/bash

# Description: this is a script for create ramdisk
# Author: neeyongliang
# Changelog: 2022.06.18 First release

set -e

fileName="rootfs.ramdisk"
gzFileName="rootfs.ramdisk.gz"
ubootFileName="rootfs.ramdisk.gz.uboot"
imgFileName="rootfs.img"

create_uboot_ramdisk() {
    if [ -f $fileName ]; then
        rm rootfs.ext*
    fi

    # generate image
    genext2fs -b 4096 -d "$1" $fileName

    # generate gzFileName
    gzip -9 $fileName

    # add ramdisk header
    mkimage \
        -n 'uboot ext4 ramdisk rootfs' \
        -A arm \
        -O linux \
        -T ramdisk \
        -C gzip \
        -d $gzFileName \
        $ubootFileName
}

create_qemu_ramdisk() {
    qemu-img create $imgFileName "$1"
    mkfs.ext4 $imgFileName
    if [ -d /tmp/tempfs ]; then
        umount /tmp/tempfs > /dev/null 2>&1
        rm -rf /tmp/tempfs
    fi
    mkdir /tmp/tempfs
    mount -o loop $imgFileName /tmp/tempfs
    sleep 1
    rm -rf /tm/tempfs/*
    cp -a "$1"/* /tmp/tempfs/
    sync
    sleep 1
    umount /tmp/tempfs/
}

if [ "$1" == "uboot" ]; then
    echo "Start create ramdisk..."
    create_uboot_ramdisk "$1"
elif [ "$1" == "qemu" ]; then
    echo "Start create ramdisk by qemu..."
    create_qemu_ramdisk "$1" "$2"
else
    echo "This script can create ramdisk, you can choose use qemu method."
    echo "Usage:"
    echo "$0 uboot ROOTFS_DIR"
    echo "$0 qemu ROOTFS_DIR ROOTFS_SIZE"
fi