#!/bin/bash

# Description: this is a script for project release to outside
# Author: neeyongliang
# Date: 2022.06.18 First release

set -e

if [ $# != 2 ]; then
	echo "Usage: $0 TAR_PREFIX DEST_NAME [debug]"
	exit 1
fi

sha256Cmd="sha256"
md5Cmd="md5sum"
uName=$(uname -s)
osName=${uName:0:4}
if [ "$osName" == "Darw" ]; then
	sha256Cmd="shasum -a 256"
	md5Cmd="md5"
fi

dateStr=$(date +'%Y%m%d')
if [ "$3" == "debug" ]; then
	echo "TAR_PREFIX: $1"
	echo "DEST_NAME: $2"
fi
srcName="$1"-"$dateStr".tar.gz

tar -cvzf "$srcName" "$2"

$sha256Cmd "$srcName" > "$srcName".sha256sum
$md5Cmd "$srcName" > "$srcName".md5
