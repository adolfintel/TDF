#!/usr/bin/env bash
# shellcheck disable=SC2164,SC1091
export LC_ALL=C

#cd to run.sh location
SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd "$DIR"

#load global config, language and launch TDF
source "vars.conf"
source "system/localization/load.sh"
if [ "$1" == "archive" ]; then
    if [ "$(type -t onArchiveStart)" == "function" ]; then
        if ! onArchiveStart "$@"; then
            exit 1
        fi
    fi
    ./system/archive.sh "$@"
    res=$?
    if [ "$(type -t onArchiveEnd)" = "function" ]; then
        onArchiveEnd $res
    fi
    exit 0
fi
if [ ! -x "./system/main.sh" ]; then
    chmod -R 777 .
fi
command="./system/main.sh"
if [ -n "$1" ]; then
    command="$command \"$*\""
else
    command="$command normal"
fi
eval "$command"
exit 0
