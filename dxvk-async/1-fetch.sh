#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading dxvk-gplasync (master)"
if [ -f incomplete ]; then
    rm -rf dxvk dxvk-gplasync build
fi
touch incomplete
if [ -d dxvk ]; then
    cd dxvk
    git fetch --all -p
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/doitsujin/dxvk
fi
if [ -d dxvk-gplasync ]; then
    cd dxvk-gplasync
    git reset --hard > /dev/null
    git fetch --all -p
    git submodule update
    cd ..
else
    git clone https://gitlab.com/Ph42oN/dxvk-gplasync/
    cd dxvk-gplasync
    git checkout test
    cd ..
fi
rm -f incomplete
echo 2 > state
exit 0
