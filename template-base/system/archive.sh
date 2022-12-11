#!/bin/bash
folderPath="$(basename "$(pwd)")"
cd ..
archivePath="$(realpath "$folderPath")"
FROMSIZE=`du -sk --apparent-size $folderPath | cut -f 1`
echo "Archiving $((FROMSIZE/1024)) MBytes:"
CHECKPOINT=`echo ${FROMSIZE}/50 | bc`
echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
if [ "$2" == "nocompress" ]; then
    archivePath="$archivePath.tar"
    echo "Output: $archivePath (no compression)"
    echo -en "\033[2A"
    tar -c --record-size=1K --checkpoint="$CHECKPOINT" --checkpoint-action="ttyout=█" -f - "$folderPath" > "$archivePath"
elif [ "$2" == "fastcompress" ]; then
    archivePath="$archivePath.tar.xz"
    echo "Output: $archivePath (parallel xz compression)"
    echo -en "\033[2A"
    tar -c --record-size=1K --checkpoint="$CHECKPOINT" --checkpoint-action="ttyout=█" -f - "$folderPath" | xz -T0 -- > "$archivePath"
else
    archivePath="$archivePath.tar.zst"
    echo "Output: $archivePath (zstd maximum compression)"
    echo -en "\033[2A"
    tar -c --record-size=1K --checkpoint="$CHECKPOINT" --checkpoint-action="ttyout=█" -f - "$folderPath" | zstd --ultra -22 > "$archivePath"
fi
if [ $? -ne 0 ]; then
    echo -e "\n\nFailed"
    exit 1
else
    echo -e "\n\nDone!"
    exit 0
fi
