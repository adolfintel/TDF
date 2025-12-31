#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading d7vk (master)"
if [ -f incomplete ]; then
    rm -rf d7vk build
fi
touch incomplete
if [ -d d7vk ]; then
    cd d7vk
    git fetch --all -p
    git reset --hard origin/master > /dev/null
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/WinterSnowfall/d7vk
fi
rm -f incomplete
echo 2 > state
exit 0
