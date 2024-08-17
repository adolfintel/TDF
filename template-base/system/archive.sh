#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034,SC2181
source "system/localization/load.sh"
folderName=$(basename "$PWD")
here=$(realpath "$PWD")
cd ..
archivePath=""
compressionMethod=""
compressionPreset=""
overwriteAllowed=0
split=""

if [ $# -ge 3 ]; then
    args=$#
    for ((i=2; i<=args; i++)); do
        p="${!i}"
        if [ "$p" == "-s" ]; then
            if [ -z "$split" ]; then
                ((i++))
                split="${!i}"
                if [ -z "$split" ]; then
                    _loc "$TDF_LOCALE_ARCHIVE_ERROR_S_MISSING"
                    exit 1
                fi
            else
                _loc "$TDF_LOCALE_ARCHIVE_ERROR_S_MULTIPLE"
                exit 1
            fi
            
        elif [ "$p" == "-f" ]; then
            overwriteAllowed=1
        elif [ "$p" == "-m" ]; then
            if [ -z "$compressionMethod" ]; then
                ((i++))
                compressionMethod="${!i}"
                if [ -z "$compressionMethod" ]; then
                    _loc "$TDF_LOCALE_ARCHIVE_ERROR_M_MISSING"
                    exit 1
                fi
            else
                _loc "$TDF_LOCALE_ARCHIVE_ERROR_M_MULTIPLE"
                exit 1
            fi
        elif [ "$p" == "-p" ]; then
            if [ -z "$compressionPreset" ]; then
                ((i++))
                compressionPreset="${!i}"
                if [ -z "$compressionPreset" ]; then
                    _loc "$TDF_LOCALE_ARCHIVE_ERROR_P_MISSING"
                    exit 1
                fi
            else
                _loc "$TDF_LOCALE_ARCHIVE_ERROR_P_MULTIPLE"
                exit 1
            fi
        elif [ "$p" == "-o" ]; then
            ((i++))
            archivePath="${!i}"
            if [ -n "$archivePath" ]; then
                if [[ "$archivePath" == /* ]]; then
                    archivePath="$(realpath "$archivePath")"
                else
                    archivePath="$(realpath "$here/$archivePath")"
                fi
                if [ -z "$compressionMethod" ]; then
                    if [[ "$archivePath" == *.tar.zst ]]; then
                        compressionMethod="zstd"
                    elif [[ "$archivePath" == *.tar.xz ]]; then
                        compressionMethod="xz"
                    elif [[ "$archivePath" == *.gz ]]; then
                        compressionMethod="gzip"
                    elif [[ "$archivePath" == *.tar ]]; then
                        compressionMethod="tar"
                    fi
                fi
            else
                _loc "$TDF_LOCALE_ARCHIVE_ERROR_O_MISSING"
                exit 1
            fi
        else
            _loc "$TDF_LOCALE_ARCHIVE_ERROR_UNKNOWNOPTION"
            echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_SYNTAX")"
            exit 1
        fi
    done
else
    if [[ -z "$2" || "$2" == "maxcompress" ]]; then
        compressionMethod="zstd"
        compressionPreset="max"
    elif [ "$2" == "fastcompress" ]; then
        compressionMethod="xz"
        compressionPreset="fast"
    elif [ "$2" == "nocompress" ]; then
        compressionMethod="tar"
    else
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_SHORT_INVALID"
        echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_SYNTAX")"
        exit 1
    fi
fi

command2=""
if [ -z "$archivePath" ]; then
    archivePath=$(realpath "$PWD/$folderName")
fi
if [ -z "$compressionMethod" ]; then
    compressionMethod="zstd"
fi
if [ "$compressionMethod" == "zstd" ]; then
    if [[ "$archivePath" != *.tar.zst ]]; then
        archivePath="$archivePath.tar.zst"
    fi
    command2="zstd"
    if [ -z "$compressionPreset" ]; then
        compressionPreset="max"
    fi
    if [ "$compressionPreset" == "max" ]; then
        command2="$command2 --ultra -22 -T1"
    elif [ "$compressionPreset" == "normal" ]; then
        command2="$command2 -19 -T0"
    elif [ "$compressionPreset" == "fast" ]; then
        command2="$command2 --fast=1 -T0"
    else
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_P_INVALID_ZSTD"
        exit 1
    fi
elif [ "$compressionMethod" == "xz" ]; then
    if [[ "$archivePath" != *.tar.xz ]]; then
        archivePath="$archivePath.tar.xz"
    fi
    command2="xz"
    if [ -z "$compressionPreset" ]; then
        compressionPreset="fast"
    fi
    if [ "$compressionPreset" == "max" ]; then
        command2="$command2 -9 -e -T1"
    elif [ "$compressionPreset" == "normal" ]; then
        command2="$command2 -9 -T0"
    elif [ "$compressionPreset" == "fast" ]; then
        command2="$command2 -6 -T0"
    else
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_P_INVALID_XZ"
        exit 1
    fi
elif [ "$compressionMethod" == "gzip" ]; then
    if [[ "$archivePath" != *.tar.gz ]]; then
        archivePath="$archivePath.tar.gz"
    fi
    command2="gzip"
    if [ -z "$compressionPreset" ]; then
        compressionPreset="normal"
    fi
    if [ "$compressionPreset" == "max" ]; then
        command2="$command2 -9"
    elif [ "$compressionPreset" == "normal" ]; then
        command2="$command2 -6"
    elif [ "$compressionPreset" == "fast" ]; then
        command2="$command2 -3"
    else
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_P_INVALID_GZIP"
        exit 1
    fi
elif [ "$compressionMethod" == "tar" ]; then
    if [[ "$archivePath" != *.tar ]]; then
        archivePath="$archivePath.tar"
    fi
    if [ -n "$compressionPreset" ]; then
        _loc "$TDF_LOCALE_ARCHIVE_WARNING_P_TAR"
        compressionPreset=""
    fi
else
    _loc "$TDF_LOCALE_ARCHIVE_ERROR_M_INVALID"
    exit 1
fi
if [[ "$archivePath" == "$here/"* ]]; then
    _loc "$TDF_LOCALE_ARCHIVE_ERROR_O_INSIDEDIR"
    exit 1
fi
if [ $overwriteAllowed -eq 0 ]; then
    find "$archivePath"* > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_O_ALREADYEXISTS"
        exit 2
    fi
fi
if ! touch "$archivePath" ; then
    _loc "$TDF_LOCALE_ARCHIVE_ERROR_O_CANTWRITE"
    exit 2
fi
rm -f "$archivePath"
startT=$SECONDS
_loc "$TDF_LOCALE_ARCHIVE_STARTED1"
_loc "$TDF_LOCALE_ARCHIVE_STARTED2"
fromSize=$( du -sk --apparent-size "$folderName" | cut -f 1 )
fromSizeMB=$((fromSize/1024))
if [ "$split" == "auto" ]; then
    if [ $fromSizeMB -le 1000 ]; then
        split="100M"
    elif [ $fromSizeMB -le 10000 ]; then
        split="1G"
    elif [ $fromSizeMB -le 100000 ]; then
        split="5G"
    elif [ $fromSizeMB -le 250000 ]; then
        split="10G"
    elif [ $fromSizeMB -le 500000 ]; then
        split="25G"
    else
        split="100G"
    fi
fi
command3=""
if [ -n "$split" ]; then
    if [[ ! "$split" =~ [1-9][0-9]*[MG] ]]; then
        _loc "$TDF_LOCALE_ARCHIVE_ERROR_S_INVALID"
        exit 1
    fi
    command3="split - -b $split \"$archivePath\""
fi
if [ -n "$split" ]; then
    _loc "$TDF_LOCALE_ARCHIVE_STARTED3"
fi
_loc "$TDF_LOCALE_ARCHIVE_STARTED4"
checkpoint="$((fromSize/50))"
command="tar -c --record-size=1K --checkpoint=$checkpoint --checkpoint-action=\"ttyout=█\" -f - \"$folderName\""
if [ -n "$command2" ]; then
    command="$command | $command2"
fi
if [ -n "$command3" ]; then
    command="$command | $command3"
else
    command="$command > \"$archivePath\""
fi
echo -en "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░\r"
eval "$command"
if [ $? -ne 0 ]; then
    echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_FAILED")"
    exit 3
else
    time=$((SECONDS - startT))
    ss=$((time % 60))
    mm=$(( ( time / 60 ) % 60 ))
    hh=$((time / 3600))
    if [ $hh -lt 1 ]; then
        hh=""
    else
        hh="${hh}h "
    fi
    if [[ $hh -lt 1 && $mm -lt 1 ]]; then
        mm=""
    else
        mm="${mm}m "
    fi
    ss="${ss}s"
    echo -e "\n$(_loc "$TDF_LOCALE_ARCHIVE_DONE")"
    if [ -n "$command3" ]; then
        toSize=$( du -ck "$archivePath"* | tail -n 1 | cut -f 1 )
    else
        toSize=$( du -sk "$archivePath" | cut -f 1 )
    fi
    ratio=$(( (100 * toSize) / fromSize ))
    toSizeMB=$((toSize/1024))
    _loc "$TDF_LOCALE_ARCHIVE_FINALSIZE"
    if [ -n "$command3" ]; then
        archiveName=$(basename "$archivePath")
        echo "#!/usr/bin/env bash" > "$archivePath.extract"
        if [ "$compressionMethod" == "zstd" ]; then
            echo "cat \"$archiveName\"* | tar --zstd -x -v -f -" >> "$archivePath.extract"
        elif [ "$compressionMethod" == "xz" ]; then
            echo "cat \"$archiveName\"* | tar -J -x -v -f -" >> "$archivePath.extract"
        elif [ "$compressionMethod" == "gzip" ]; then
            echo "cat \"$archiveName\"* | tar -z -x -v -f -" >> "$archivePath.extract"
        elif [ "$compressionMethod" == "tar" ]; then
            echo "cat \"$archiveName\"* | tar -x -v -f -" >> "$archivePath.extract"
        fi
        chmod +x "$archivePath.extract"
    fi
    exit 0
fi
