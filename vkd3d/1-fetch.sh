#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading vkd3d-proton (master)"
if [ -f incomplete ]; then
    rm -rf vkd3d-proton build
fi
touch incomplete
if [ -d vkd3d-proton ]; then
    cd vkd3d-proton
    git fetch --all -p
    git reset --hard origin/master > /dev/null
    git submodule update
    cd ..
else
    git clone --recursive https://github.com/HansKristian-Work/vkd3d-proton
fi
rm -f incomplete
echo 2 > state
exit 0
