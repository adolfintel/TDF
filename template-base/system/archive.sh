#!/bin/bash
folderPath="$(basename "$(pwd)")"
cd ..
archivePath="$(realpath "$folderPath")"
if [ "$2" == "nocompress" ]; then
    archivePath="$archivePath.tar"
    echo "Archiving to $archivePath without compression"
    sleep 1
    tar -cvf "$archivePath" "$folderPath"
else
    archivePath="$archivePath.tar.zst"
    echo "Compressing to $archivePath"
    sleep 1
    tar -I 'zstd --ultra -22' -cvf "$archivePath" "$folderPath"
fi
if [ $? -ne 0 ]; then
    echo "Failed"
    exit 1
else
    echo "Saved to $archivePath"
    exit 0
fi
