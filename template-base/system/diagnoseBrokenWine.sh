#!/usr/bin/env bash
#shellcheck disable=SC2155,SC1091,SC2164

source "system/localization/load.sh"

_missingLibs64=""
function _checkMissingLibs(){
    local oldDir="$PWD"
    if ! cd "$1" ; then
        return 0;
    fi
    local canRun=1
    _missingLibs64=""
    local oldIFS="$IFS"
    IFS=$'\n'
    local missing=$(ldd bin/* lib/wine/*-unix/* 2>/dev/null | grep "=> not found" | sort | uniq)
    for f in $missing; do
        f="${f:1:-13}"
        # shellcheck disable=SC2046
        if [ $(find . -name "$f" | wc -l) -eq 0 ]; then
            _missingLibs64="$f $_missingLibs64"
            canRun=0
        fi
    done
    IFS="$oldIFS"
    cd "$oldDir"
    return $canRun
}

if [[ "$1" = "$PWD/"* ]]; then
    _checkMissingLibs "$1/.."
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        _loc "$TDF_LOCALE_WINE_MISSINGDEPS"
        exit
    else
        _loc "$TDF_LOCALE_WINE_BROKEN"
        exit
    fi
else
    _loc "$TDF_LOCALE_WINE_BROKEN"
    exit
fi
