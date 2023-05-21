#!/bin/bash
export LC_ALL=C
SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd "$DIR"
USE_STEAMRT=1
IGNORE_MECHANICAL_HDD=0
mustShowHDDWarning=0
mechanicalDriveMessage="Running from a mechanical hard drive is not recommended, expect performance issues"
source "vars.conf"
if [ "$1" == "archive" ]; then
    if [ "$(type -t onArchiveStart)" == "function" ]; then
        onArchiveStart "$@"
    fi
    ./system/archive.sh "$@"
    res=$?
    if [ "$(type -t onArchiveEnd)" == "function" ]; then
        onArchiveEnd $res
    fi
    exit
fi
if [ $IGNORE_MECHANICAL_HDD -eq 0 ]; then
    drive=$(df -T . | awk '/^\/dev/ {print $1}')
    drive=$(lsblk -no pkname "$drive")
    isMechanical="$(cat /sys/block/"$drive"/queue/rotational)"
    if [ "$isMechanical" == "1" ]; then
        mustShowHDDWarning=1
    else
        mustShowHDDWarning=0
    fi
fi
if [ ! -x "./system/main.sh" ]; then
    chmod -R 777 .
fi
if [ $USE_STEAMRT -eq 1 ] && [ -e "./system/steamrt" ]; then
    if [ $mustShowHDDWarning -eq 1 ]; then
        ./system/steamrt/run.sh zenity --warning --width 400 --text "$mechanicalDriveMessage"
    fi
    ./system/steamrt/setup.sh
    if [ -n "$1" ]; then 
        ./system/steamrt/run.sh ./system/main.sh "$@"
    else
        ./system/steamrt/run.sh ./system/main.sh normal
    fi
    
else
    if [ $mustShowHDDWarning -eq 1 ]; then
        zenity --warning --width 400 --text "$mechanicalDriveMessage"
    fi
    if [ -n "$1" ]; then 
        ./system/main.sh "$@"
    else
        ./system/main.sh normal
    fi
fi
