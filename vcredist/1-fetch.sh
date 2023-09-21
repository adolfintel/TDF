#!/usr/bin/env bash
set -e
echo 1 > state
echo "Downloading vcredist"
if [ -f incomplete ]; then
    rm -rf build
fi
touch incomplete
if [ ! -d build ]; then
    mkdir build
fi
cd build
wget -N https://aka.ms/vs/17/release/vc_redist.x64.exe
wget -N https://aka.ms/vs/17/release/vc_redist.x86.exe
cd ..
rm -f incomplete
echo 2 > state
exit 0
