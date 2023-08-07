#!/bin/bash

############################################################
# Description: scp performance bench script
# Feature: automaic check multiples algorithm
# Author: yongliang <neeyongliang@gmail.com>
# Refer:
# - https://gist.github.com/SAPikachu/c276860e466c36070904
#############################################################

cd /tmp || exit 1

if [ ! -f test ]; then
    dd if=/dev/urandom of=file500M count=1 size=500m
fi

ALGS=$(ssh -Q cipher)

for ALG in "${ALGS[@]}"; do
    # Warm up
    # echo "scp warm up, using $ALG..."
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null > /dev/null 2>&1
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null > /dev/null 2>&1
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null > /dev/null 2>&1

    # Real test
    echo "scp real test, using $ALG..."
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null 2>&1 | grep "Bytes per second"
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null 2>&1 | grep "Bytes per second"
    scp -o Compression=no -c "$ALG" -v ./file500M 127.0.0.1:/dev/null 2>&1 | grep "Bytes per second"
done
