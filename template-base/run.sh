#!/usr/bin/env bash
export LC_ALL=C

# --- VARIABLES - Steam Runtime ---
TDF_STEAM_RUNTIME=2

#cd to run.sh location
SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd "$DIR"

#load global config
source "vars.conf"

#launch archive mode if requested
if [ "$1" == "archive" ]; then
    if [ "$(type -t onArchiveStart)" == "function" ]; then
        onArchiveStart "$@"
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
    ./system/archive.sh "$@"
    res=$?
    if [ "$(type -t onArchiveEnd)" == "function" ]; then
        onArchiveEnd $res
    fi
    exit 0
fi

#otherwise, launch TDF
command -v zenity > /dev/null
    if [ $? -eq 0 ]; then
    (
        rm .tdfok
        for i in {1..100}; do
            if [ -e .tdfok ]; then
                rm .tdfok
                break;
            fi
            sleep 0.1
        done
    ) | zenity --progress --no-cancel --text="Launching..." --width=250 --auto-close --auto-kill &
fi
if [ ! -x "./system/main.sh" ]; then
    chmod -R 777 .
fi
if [ "$XDG_SESSION_TYPE" == "x11" ]; then
    export _DPI_FROM_OS="$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)"
else #TODO: wayland support (0 lets wine handle it)
    export _DPI_FROM_OS=0
fi
command="./system/main.sh"
function found(){
    command -v "$1" > /dev/null
    return $?
}
if [ $TDF_STEAM_RUNTIME -eq 2 ]; then
    found wine && found wine64 && found winepath && found wineserver && found zenity && found xrandr && found unshare && found flock && found cmp
    if [ $? -eq 0 ]; then
        TDF_STEAM_RUNTIME=0
    else
        TDF_STEAM_RUNTIME=1
    fi
fi
if [ $TDF_STEAM_RUNTIME -eq 1 ] && [ -d "./system/steamrt" ]; then
    tar -xf ./system/steamrt/depot/sniper_platform_*/files/share/ca-certificates.tar -C ./system/steamrt/depot/sniper_platform_*/files/share
    command="./system/steamrt/depot/run --no-generate-locales $command"
fi
if [ -n "$1" ]; then
    command="$command \"$*\""
else
    command="$command normal"
fi
eval "$command"
exit 0
