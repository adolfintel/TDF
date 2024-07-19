#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034,SC2181
source "system/localization/load.sh"
folderPath="$(basename "$(pwd)")"
cd ..
archivePath="$(realpath "$folderPath")"
fromSize=$( du -sk --apparent-size "$folderPath" | cut -f 1 )
fromSizeMB=$((fromSize/1024))
_loc "$TDF_LOCALE_ARCHIVE_STARTED"
checkpoint="$((fromSize/50))"
command="tar -c --record-size=1K --checkpoint=$checkpoint --checkpoint-action=\"ttyout=█\" -f - \"$folderPath\""
if [ "$2" == "nocompress" ]; then
    archivePath="$archivePath.tar"
    _loc "$TDF_LOCALE_ARCHIVE_TAR"
elif [ "$2" == "fastcompress" ]; then
    archivePath="$archivePath.tar.xz"
    _loc "$TDF_LOCALE_ARCHIVE_XZ"
    command="$command | xz -T0"
elif [ "$2" == "maxcompress" ] || [ -z "$2" ]; then
    archivePath="$archivePath.tar.zst"
    _loc "$TDF_LOCALE_ARCHIVE_ZSTD"
    command="$command | zstd --ultra -22"
else
    _loc "$TDF_LOCALE_ARCHIVE_INVALIDARGS"
    exit 2
fi
echo -en "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\r"
eval "$command" > "$archivePath"
if [ $? -ne 0 ]; then
    echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_FAILED")"
    exit 1
else
    echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_DONE")"
    toSize=$( du -sk "$archivePath" | cut -f 1 )
    ratio=$(( (100 * toSize) / fromSize ))
    toSizeMB=$((toSize/1024))
    _loc "$TDF_LOCALE_ARCHIVE_FINALSIZE"
    exit 0
fi
