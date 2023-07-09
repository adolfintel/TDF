#!/usr/bin/env bash

WINDOWS=()
WINDOW=""

function activateWindow(){
    xdotool windowactivate "$1"
}

function pressKey(){
    local n=1
    if [ ! -z "$2" ]; then
        n="$2"
    fi
    for i in $(seq 1 $n); do
        xdotool key "$1"
        sleep 0.5
    done
}

function focusWindow(){
    xdotool windowfocus "$1"
    xdotool windowactivate "$1"
    if [ $? -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

function makeFullscreen(){
    xdotool windowstate --add FULLSCREEN "$1"
    focusWindow $1
}

function removeFullscreen(){
    xdotool windowstate --remove FULLSCREEN "$1"
}

function maximizeWindow(){
    xdotool windowstate --add MAXIMIZED_VERT "$1"
    xdotool windowstate --add MAXIMIZED_HORZ "$1"
}

function minimizeWindow(){
    xdotool windowminimize "$1"
}

function restoreWindow(){
    xdotool windowstate --remove MAXIMIZED_VERT "$1"
    xdotool windowstate --remove MAXIMIZED_HORZ "$1"
}

function moveWindow(){
    xdotool windowmove "$1" "$2" "$3"
}

function resizeWindow(){
    xdotool windowsize "$1" "$2" "$3"
}

function altEnter(){
    pressKey "alt+enter"
}

function waitForWindow(){
    local timeout=30
    if [ ! -z "$3" ]; then
        timeout="$3"
    fi
    local args="--shell --onlyvisible"
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

function keepWindowFocused(){
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

function keepWindowFocusedById(){
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
