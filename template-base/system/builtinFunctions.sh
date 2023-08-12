#!/usr/bin/env bash

WINDOWS=()
WINDOW=""
_savedGamma="1:1:1"

TDF_XDOTOOL_ONLY_VISIBLE=0

function pressKey {
    local n=1
    if [ ! -z "$2" ]; then
        n="$2"
    fi
    for i in $(seq 1 $n); do
        xdotool key "$1"
        sleep 0.5
    done
}

function focusWindow {
    xdotool windowfocus "$1"
    xdotool windowactivate "$1"
    if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

function makeFullscreen {
    xdotool windowstate --add FULLSCREEN "$1"
    focusWindow $1
}

function removeFullscreen {
    xdotool windowstate --remove FULLSCREEN "$1"
}

function maximizeWindow {
    xdotool windowstate --add MAXIMIZED_VERT "$1"
    xdotool windowstate --add MAXIMIZED_HORZ "$1"
}

function restoreWindow {
    xdotool windowstate --remove MAXIMIZED_VERT "$1"
    xdotool windowstate --remove MAXIMIZED_HORZ "$1"
}

function minimizeWindow {
    xdotool windowminimize "$1"
}

function activateWindow {
    xdotool windowactivate "$1"
}

function moveWindow {
    xdotool windowmove "$1" "$2" "$3"
}

function resizeWindow {
    xdotool windowsize "$1" "$2" "$3"
}

function waitForWindow {
    local timeout=30
    if [ ! -z "$3" ]; then
        timeout="$3"
    fi
    local args="--shell"
    if [ "$TDF_XDOTOOL_ONLY_VISIBLE" -eq 1 ]; then
        args="$args --onlyvisible"
    fi
    for i in $(seq 1 $timeout); do
        local idE=()
        local idN=()
        if [ ! -z "$1" ]; then
            eval $(xdotool search $args --classname "$1")
            for i in "${WINDOWS[@]}"; do
                idE+=("$i")
            done
        fi
        if [ ! -z "$2" ]; then
            eval $(xdotool search $args --name "$2")
            for i in "${WINDOWS[@]}"; do
                idN+=("$i")
            done
        fi
        WINDOWS=()
        WINDOW=""
        local done=0
        if [ -z "$1" ]; then
            for i in "${idN[@]}"; do
                WINDOWS+=("$i")
                done=1
            done
        elif [ -z "$2" ]; then
            for i in "${idE[@]}"; do
                WINDOWS+=("$i")
                done=1
            done
        else
            for a in "${idE[@]}"; do
                for b in "${idN[@]}"; do
                    if [ "$a" == "$b" ]; then
                        WINDOWS+=("$i")
                        done=1
                        break
                    fi
                done
            done
        fi
        if [ $done -eq 1 ]; then
            WINDOW="${WINDOWS[0]}"
            return 0
        fi
        sleep 1
    done
    WINDOWS=()
    WINDOW=""
    return 1
}

function keepWindowFocused {
    local timeout=30
    if [ ! -z "$3" ]; then
        timeout="$3"
    fi
    waitForWindow "$1" "$2" "$timeout"
    local ok=1
    while [ $ok -eq 1 ]; do
        ok=0
        waitForWindow "$1" "$2" 1
        for id in "${WINDOWS[@]}"; do
            ok=1
            focusWindow "$id"
        done
        sleep 1
    done
}

function keepWindowFocusedById {
    local first=1
    while true; do
        focusWindow "$1"
        if [ $? -ne 0 ]; then
            if [ $first -eq 1 ]; then
                return 1
            else
                return 0
            fi
        fi
        first=0
        sleep 1
    done
}

function saveGamma {
    xrandr --version > /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    local primaryDisplay="$(xrandr | grep "primary" | cut -d ' ' -f1)"
    if [ -n "$primaryDisplay" ]; then
        local g=$(xrandr --verbose | sed -n "/$primaryDisplay/,/Gamma/p" | grep "Gamma")
        if [ -n "$g" ]; then
            _savedGamma=$(echo "$g" | cut -d ':' -f2):$(echo "$g" | cut -d ':' -f3):$(echo "$g" | cut -d ':' -f4)
        fi
    fi
    return 0
}

function setGamma {
    xrandr --version > /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    if [[ "$1" =~ ^[0-9.]*$ ]]; then
        xrandr --output $(xrandr | grep "primary" | cut -d ' ' -f1) --gamma $1:$1:$1
    else
        xrandr --output $(xrandr | grep "primary" | cut -d ' ' -f1) --gamma $1
    fi
    return 0
}

function restoreGamma {
    setGamma $_savedGamma
    return $?
}

function defaultGamma {
    setGamma "1:1:1"
    return $?
}

saveGamma
