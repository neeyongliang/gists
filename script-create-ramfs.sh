#! /bin/bash

if [ ! -d "rootfs" ]; then
	echo "cannot find rootfs directory."
fi

set -e
if [ -e ramfs.img ]; then
	rm ramfs.img
fi
cd rootfs
find . | cpio -o -H newc | gzip > ../ramfs.img
cd ..
