#!/bin/bash

currKernel="Upstream_Image_4.19.221"
if [ "$1" == "qemu" ]; then
	if [ ! -f "test.img" ]; then
		echo "Error: using qemu mode, cannot find test.img!"
		exit 1
	fi
	storageArg="-hda test.img"
	appendArg="--append \"root=/dev/vda rootfstype=ext4 rw selinux=0 init=/linuxrc\""
else
	if [ ! -f "test.img.gz" ]; then
		echo "Error: using manual mode, cannot find test.img.gz!"
		exit 1
	fi
	storageArg="-initrd ramfs.img.gz"
	appendArg="-append \"loglevel=7 rdinit=/linuxrc ro\""
fi

qemu-system-aarch64 \
	-cpu cortex-a57 \
	-M virt \
	-nographic \
	-smp 4 \
	-m 2048M \
	-kernel $currKernel \
	-net nic,model=e1000 \
	-net tap,ifname=tap0,script=no,downscript=no \
	"$storageArg" \
	"$appendArg"