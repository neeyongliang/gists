#! /bin/bash

# Description: this is a script for create ramfs
# Author: neeyongliang
# Date: 2022.06.18 First release

set -e

if [ ! -d "rootfs" ]; then
	echo "cannot find rootfs directory."
	exit 1
fi

if [ -e ramfs.img ]; then
	rm ramfs.img
fi
cd rootfs
find . | cpio -o -H newc | gzip > ../ramfs.img
cd ..
