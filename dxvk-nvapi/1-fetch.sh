#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading dxvk-nvapi (master)"
if [ -f incomplete ]; then
    rm -rf dxvk-nvapi build
fi
touch incomplete
if [ -d dxvk-nvapi ]; then
    cd dxvk-nvapi
    git fetch --all -p
    git reset --hard origin/master > /dev/null
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/jp7677/dxvk-nvapi
fi
rm -f incomplete
echo 2 > state
exit 0
