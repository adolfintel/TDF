#!/usr/bin/env bash

if [ -n "$TDF_UI_LANGUAGE" ]; then
    _l="$TDF_UI_LANGUAGE"
    export TDF_UI_LANGUAGE
elif [ -n "$LANG" ]; then
    _l="$LANG"
fi
function _loc {
    local delim="__apply_shell_expansion_delimiter__"
    eval "cat <<$delim"$'\n'"$1"$'\n'"$delim"
}
function _tryLoadLocale {
    if [ -f "system/localization/$1.conf" ]; then
        source "system/localization/$1.conf"
    else
        local lowercase="${1,,}"
        if [ -f "system/localization/$lowercase.conf" ]; then
            source "system/localization/$lowercase.conf"
        fi
    fi
}

_tryLoadLocale "en"
if [ -n "$_l" ]; then
    _tryLoadLocale "${_l%.*}"
    _tryLoadLocale "${_l%_*}"
    _tryLoadLocale "$_l"
fi
