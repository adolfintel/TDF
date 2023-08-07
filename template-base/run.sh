#!/usr/bin/env bash
export LC_ALL=C

# --- VARIABLES - Steam runtime ---
TDF_USE_STEAM_RUNTIME=1

#cd to run.sh location
SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd "$DIR"

#load global config and launch TDF
source "vars.conf"
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
if [ ! -x "./system/main.sh" ]; then
    chmod -R 777 .
fi
if [ "$XDG_SESSION_TYPE" == "x11" ]; then
    export _DPI_FROM_OS="$(xrdb -query | grep dpi | cut -f2 -d':' | xargs)"
else #TODO: wayland support (0 lets wine handle it)
    export _DPI_FROM_OS=0
fi
command="./system/main.sh"
if [ $TDF_USE_STEAM_RUNTIME -eq 1 ] && [ -d "./system/steamrt" ]; then
    tar -xf ./system/steamrt/depot/sniper_platform_*/files/share/ca-certificates.tar -C ./system/steamrt/depot/sniper_platform_*/files/share
    command="./system/steamrt/depot/run $command"
fi
if [ -n "$1" ]; then
    command="$command \"$*\""
else
    command="$command normal"
fi
eval "$command"
exit 0
