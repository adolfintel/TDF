#!/usr/bin/env bash

_savedGamma="1:1:1"

function saveGamma(){
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

function setGamma(){
    xrandr --version > /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    xrandr --output $(xrandr | grep "primary" | cut -d ' ' -f1) --gamma $1
    return 0
}

function restoreGamma(){
    setGamma $_savedGamma
    return $?
}

function defaultGamma(){
    setGamma "1:1:1"
    return $?
}

saveGamma
