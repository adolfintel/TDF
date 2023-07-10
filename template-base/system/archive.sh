#!/usr/bin/env bash
folderPath="$(basename "$(pwd)")"
cd ..
archivePath="$(realpath "$folderPath")"
fromSize=$( du -sk --apparent-size "$folderPath" | cut -f 1 )
echo "Archiving  $((fromSize/1024)) MBytes"
checkpoint="$((fromSize/50))"
command="tar -c --record-size=1K --checkpoint=$checkpoint --checkpoint-action=\"ttyout=█\" -f - \"$folderPath\""
if [ "$2" == "nocompress" ]; then
    archivePath="$archivePath.tar"
    echo "Output: $archivePath (no compression)"
elif [ "$2" == "fastcompress" ]; then
    archivePath="$archivePath.tar.xz"
    echo "Output: $archivePath (parallel xz compression)"
    command="$command | xz -T0"
elif [ "$2" == "maxcompress" ] || [ -z "$2" ]; then
    archivePath="$archivePath.tar.zst"
    echo "Output: $archivePath (zstd maximum compression)"
    command="$command | zstd --ultra -22"
else
    echo "Error: valid options for compression are nocompress, fastcompress or maxcompress"
    exit 2
fi
echo -en "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\r"
eval "$command" > "$archivePath"
if [ $? -ne 0 ]; then
    echo -e "\nFailed"
    exit 1
else
    echo -e "\nDone!"
    toSize=$( du -sk "$archivePath" | cut -f 1 )
    ratio=$(( (100 * toSize) / fromSize ))
    echo "Final size: $((toSize/1024)) MBytes ($ratio% compression ratio)"
    exit 0
fi
