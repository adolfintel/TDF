#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading xdotool (master)"
if [ -f incomplete ]; then
    rm -rf xdotool build
fi
touch incomplete
if [ -d xdotool ]; then
    cd xdotool
    git fetch --all -p
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/jordansissel/xdotool.git
fi
rm -f incomplete
echo 2 > state
exit 0
