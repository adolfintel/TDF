#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading d8vk (master)"
if [ -f incomplete ]; then
    rm -rf d8vk build
fi
touch incomplete
if [ -d d8vk ]; then
    cd d8vk
    git fetch --all -p
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/AlpyneDreams/d8vk.git
fi
rm -f incomplete
echo 2 > state
exit 0
